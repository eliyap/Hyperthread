//
//  AsyncFollowUp.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 7/1/22.
//

import Foundation
import Twig
import RealmSwift
import Algorithms

/// An error we can surface to the user.
/// *Not* an error on the user's part.
public enum UserError: Error {
    case fetch(Error)
    case credentials
    case database
    case nilSelf /// Special case for when `weak` resolves to `nil`.
}

/** Handles the "follow up" logic for `Conversation`s and `Discussion`s.
 */
actor ReferenceCrawler {
    
    /// Singleton Object.
    public static let shared: ReferenceCrawler = .init()
    private init() {}
    
    private var inFlight: Set<Tweet.ID> = []
    
    /// Dispatch a fetch request for a single tweet.
    public func fetchSingle(id: Tweet.ID) async -> Void {
        await intermediate(conversationsDangling: [], discussionsDangling: [], unlinked: [id])
    }
    
    /// Follow up `Conversation`s without a `Discussion` and relevant `Discussions` with dangling references.
    /// Returns when all `Conversation`s are followed up, but continues fetching `Discussions` asynchronously.
    /// Rationale: Linking `Conversation`s can result in new `Discussion`s being added, which is more disruptive to the UI.
    public func performFollowUp() async -> Void {
        var conversationsDangling: Set<Tweet.ID> = []
        var discussionsDangling: Set<Tweet.ID> = []
        var unlinked: Set<Tweet.ID> = []
        repeat {
            conversationsDangling = Self.getDiscussionsDangling()
            discussionsDangling = Self.getDiscussionsDangling()
            await intermediate(
                conversationsDangling: conversationsDangling,
                discussionsDangling: discussionsDangling,
                unlinked: unlinked
            )
            
            /// Perform linking.
            do {
                unlinked = try linkUnlinked()
            } catch {
                ModelLog.error("Linking error: \(error)")
                assert(false)
            }
        } while conversationsDangling.isNotEmpty
        
        /// Continue to follow up dangling `Discussion` references
        /// even after we've chased down all the `Conversation`s.
        Task {
            var conversationsDangling: Set<Tweet.ID> = []
            var discussionsDangling: Set<Tweet.ID> = []
            var unlinked: Set<Tweet.ID> = []
            repeat {
                /// Though we *think* conversations are done, feel free to be proven wrong.
                conversationsDangling = Self.getDiscussionsDangling()
                if conversationsDangling.isNotEmpty {
                    NetLog.warning("Unexpected conversation follow up!")
                }
                
                discussionsDangling = Self.getDiscussionsDangling()
                await intermediate(
                    conversationsDangling: conversationsDangling,
                    discussionsDangling: discussionsDangling,
                    unlinked: unlinked
                )
                
                /// Perform linking.
                do {
                    unlinked = try linkUnlinked()
                } catch {
                    ModelLog.error("Linking error: \(error)")
                    assert(false)
                }
            } while conversationsDangling.isNotEmpty || discussionsDangling.isNotEmpty
        }
    }
    
    private func intermediate(
        conversationsDangling: Set<Tweet.ID>,
        discussionsDangling: Set<Tweet.ID>,
        unlinked: Set<Tweet.ID>
    ) async {
        /// Join lists.
        let fetchList = conversationsDangling.union(discussionsDangling).union(unlinked)
            /// Check that we're not already fetching these.
            .filter { inFlight.contains($0) == false }
        
        /// Record that these tweets are being fetched.
        inFlight.formUnion(fetchList)
        
        var mentionsCollector: MentionList = []
        await withTaskGroup(of: FetchResult.self) { group in
            fetchList
                .chunks(ofCount: TweetEndpoint.maxResults)
                .forEach { chunk in
                    group.addTask { [weak self] in
                        await self?.fetch(ids: Array(chunk)) ?? .failure(.nilSelf)
                    }
                }
            
            /// Collect mention list together.
            for await result in group {
                if case .success(let list) = result {
                    mentionsCollector.formUnion(list)
                }
            }
        }
        
        /// Set constant to dispel error.
        let mentions = mentionsCollector
        
        /// Dispatch task for missing users. Not necessary to continue.
        Task {
            await withTaskGroup(of: Void.self) { group in
                mentions
                    .chunks(ofCount: UserEndpoint.maxResults)
                    .forEach { chunk in
                        group.addTask {
                            await UserFetcher.fetchAndStoreUsers(ids: Array(chunk))
                        }
                    }
            }
        }
    }
    
    /// List of users mentioned that need to be fetched.
    private typealias MentionList = Set<User.ID>
    private typealias FetchResult = Result<MentionList, UserError>
    private func fetch(ids: [Tweet.ID]) async -> FetchResult {
        guard let credentials = Auth.shared.credentials else {
            return .failure(.credentials)
        }
        
        var rawData: RawData
        var followingIDs: [User.ID]
        do {
            /// Dispatch requests in parallel.
            async let _rawData = hydratedTweets(credentials: credentials, ids: ids)
            async let _followingIDs = FollowingCache.shared.request()
            (rawData, followingIDs) = try await (_rawData, _followingIDs)
        } catch {
            NetLog.error("Follow up fetch error: \(error)")
            return .failure(.fetch(error))
        }
        
        /// Unbundle tuple.
        let (tweets, _, users, _) = rawData
        
        /// Remove tweets from list.
        for tweet in tweets {
            inFlight.remove(tweet.id)
        }
        do {
            try Self.store(rawData: rawData, followingIDs: followingIDs)
        } catch {
            return .failure(.database)
        }
        
        let missingMentions = findMissingMentions(tweets: tweets, users: users)
        return .success(missingMentions)
    }
    
    /// Perform `Realm` work to store the fetched data.
    private static func store(rawData: RawData, followingIDs: [User.ID]) throws -> Void {
        /// Unbundle tuple.
        let (tweets, included, users, media) = rawData
        
        /// Safe to insert `included`, as we make no assumptions around `Relevance`.
        try ingestRaw(rawTweets: tweets + included, rawUsers: users, rawMedia: media, following: followingIDs)
        
        let realm = try! Realm()
        try realm.updateDangling()
    }
    
    private static func getConversationsDangling() -> Set<Tweet.ID> {
        let realm = try! Realm()
        
        /// Find all conversations without a `Discussion`.
        /// - Note: We do **not** apply a `Relevance` filter here.
        ///   - Consider the case where
        ///     - you follow C, but not B or A,
        ///     - C quotes B, who quotes A.
        ///   - C's conversation is "relevant", but B's is not.
        ///   - Nevertheless B's conversation must be followed up to complete the `Discussion`.
        let c = realm.objects(Conversation.self)
            .filter(NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "\(Conversation.discussionPropertyName).@count == 0")
            ]))
        NetLog.debug("\(c.count) conversations requiring follow up.", print: true, true)
        
        return c
            .map { $0.getFollowUp() }
            .reduce(Set<Tweet.ID>()) { $0.union($1) }
    }
    
    private static func getDiscussionsDangling() -> Set<Tweet.ID> {
        let realm = try! Realm()
        
        let d = realm.objects(Discussion.self)
            .filter(NSCompoundPredicate(andPredicateWithSubpredicates: [
            /// Check if any `Tweet` is above the relevance threshold.
            Discussion.minRelevancePredicate,
            
            /// Check if any `Tweet` has dangling references.
            Discussion.danglingReferencePredicate,
        ]))
        NetLog.debug("\(d.count) discussions requiring follow up.", print: true, true)
        
        return d
            .map { $0.getFollowUp() }
            .reduce(Set<Tweet.ID>()) { $0.union($1) }
    }
}
