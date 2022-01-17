//
//  ReferenceCrawler.swift
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
    
    /// Set of tweets for which we received no response from Twitter.
    private var unavailable: Set<Tweet.ID> = []
    
    /// Tweets where we are waiting for a response, and which should not yet be re-requested.
    private var inFlight: Set<Tweet.ID> = []
    
    /// Dispatch a fetch request for a single tweet.
    public func fetchSingle(id: Tweet.ID) async -> Void {
        await intermediate(fetchList: [id])
    }
    
    /// Follow up `Conversation`s without a `Discussion` and relevant `Discussions` with dangling references.
    /// Returns when all `Conversation`s are followed up, but continues fetching `Discussions` asynchronously.
    /// Rationale: Linking `Conversation`s can result in new `Discussion`s being added, which is more disruptive to the UI.
    public func performFollowUp() async -> Void {
        var conversationsDangling: Set<Tweet.ID> = []
        var discussionsDangling: Set<Tweet.ID> = []
        var unlinked: Set<Tweet.ID> = []
        repeat {
            /// Pre-filter so that `repeat-while` loop condition is accurate.
            conversationsDangling = Self.getConversationsDangling()
                .filter { inFlight.contains($0) == false && unavailable.contains($0) == false }
            discussionsDangling = Self.getDiscussionsDangling()
                .filter { inFlight.contains($0) == false && unavailable.contains($0) == false }
            let unlinkedFiltered = unlinked
                .filter { inFlight.contains($0) == false && unavailable.contains($0) == false }
            
            let fetchList = conversationsDangling.union(discussionsDangling).union(unlinkedFiltered)
            
            /// If all tweets are block-listed, we can get stuck in a loop.
            guard fetchList.isNotEmpty else { break }
            
            await intermediate(fetchList: fetchList)
            
            /// Perform linking.
            do {
                unlinked = try linkConversations()
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
                /// Pre-filter so that `repeat-while` loop condition is accurate.
                /// Though we *think* conversations are done, feel free to be proven wrong.
                conversationsDangling = Self.getConversationsDangling()
                    .filter { inFlight.contains($0) == false && unavailable.contains($0) == false }
                if conversationsDangling.isNotEmpty {
                    NetLog.warning("Unexpected conversation follow up!")
                }
                
                discussionsDangling = Self.getDiscussionsDangling()
                    .filter { inFlight.contains($0) == false && unavailable.contains($0) == false }
                let unlinkedFiltered = unlinked
                    .filter { inFlight.contains($0) == false && unavailable.contains($0) == false }
                
                let fetchList = conversationsDangling.union(discussionsDangling).union(unlinkedFiltered)
                
                /// If all tweets are block-listed, we can get stuck in a loop.
                guard fetchList.isNotEmpty else { break }
                
                await intermediate(fetchList: fetchList)
                
                /// Perform linking.
                do {
                    unlinked = try linkConversations()
                } catch {
                    ModelLog.error("Linking error: \(error)")
                    assert(false)
                }
            } while conversationsDangling.isNotEmpty || discussionsDangling.isNotEmpty
        }
    }
    
    private func intermediate(fetchList: Set<Tweet.ID>) async {
        /// Record that these tweets are being fetched.
        inFlight.formUnion(fetchList)
        
        NetLog.debug("Dispatching request for \(fetchList.count) tweets \(Array(fetchList).truncated(5))", print: true, true)
        
        let mentions: MentionList = await withTaskGroup(of: FetchResult.self) { group -> MentionList in
            /// Dispatch chunked requests in parallel.
            fetchList
                .chunks(ofCount: TweetEndpoint.maxResults)
                .forEach { chunk in
                    group.addTask { [weak self] in
                        await self?.fetch(ids: Array(chunk)) ?? .failure(.nilSelf)
                    }
                }
            
            /// Collect mention list together.
            var results: MentionList = []
            for await fetchResult in group {
                switch fetchResult {
                case .success(let list):
                    results.formUnion(list)
                case .failure(let userError):
                    NetLog.error("\(userError)")
                    assert(false)
                }
            }
            
            return results
        }
        
        /// Check if any tweets failed to land.
        /// - Note: tweets may fail to land due to being deleted.
        if inFlight.isNotEmpty {
            NetLog.log(.info, """
                \(inFlight.count) tweets failed to land!
                IDs \(inFlight)
                """)
            
            /// Empty out the inflight list.
            unavailable.formUnion(inFlight)
            inFlight = []
        }
        
        /// Dispatch task for missing users. Not necessary to continue.
        Task {
            await withTaskGroup(of: Void.self) { group in
                mentions
                    .chunks(ofCount: UserEndpoint.maxResults)
                    .forEach { chunk in
                        group.addTask {
                            await fetchAndStoreUsers(ids: Array(chunk))
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
        
        do {
            try store(rawData: rawData, followingIDs: followingIDs)
        } catch {
            return .failure(.database)
        }
        
        /// Remove tweets from list *after* they've landed.
        for tweet in tweets {
            inFlight.remove(tweet.id)
        }
        
        let missingMentions = findMissingMentions(tweets: tweets, users: users)
        return .success(missingMentions)
    }
    
    /// Perform `Realm` work to store the fetched data.
    private func store(rawData: RawData, followingIDs: [User.ID]) throws -> Void {
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
