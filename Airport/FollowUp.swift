//
//  FollowUp.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 23/12/21.
//

import Foundation
import Combine
import RealmSwift
import Twig

final class FollowUp {
    private var pipeline: AnyCancellable? = nil
    public let intake = PassthroughSubject<Void, Never>()
    public let recycle = PassthroughSubject<[Tweet.ID], Never>()
    init() {
        var inFlight: Set<Tweet.ID> = []
        
        let intakePublisher = intake
            /// Synchronize
            .receive(on: Airport.scheduler)
            .map { (_) -> Set<Tweet.ID> in
                let realm = try! Realm()
                var toFetch: Set<Tweet.ID> = []
                
                let c = realm.conversationsWithFollowUp()
                    .map { $0.getFollowUp(realm: realm) }
                    .reduce(Set<Tweet.ID>()) { $0.union($1) }
                toFetch.formUnion(c)
                
                let d = realm.discussionsWithFollowUp()
                    .map { $0.getFollowUp() }
                    .reduce(Set<Tweet.ID>()) { $0.union($1) }
                toFetch.formUnion(d)
                
                Swift.debugPrint("\(realm.conversationsWithFollowUp().count) conversations requiring follow up." as NSString)
                Swift.debugPrint("\(realm.discussionsWithFollowUp().count) discussions requiring follow up." as NSString)
                return toFetch
            }
            .map { Array($0) }
        
        self.pipeline = intakePublisher.merge(with: recycle)
            .map {
                $0.filter { inFlight.contains($0) == false }
            }
            .map { (ids: [Tweet.ID]) -> [Tweet.ID] in
                inFlight.formUnion(ids)
                NetLog.debug("Requesting \(ids.count) tweets", print: true, true)
                return ids
            }
            .v2Fetch()
            /// Synchronize
            .receive(on: Airport.scheduler)
            .deferredBuffer(FollowingFetcher.self, timer: FollowingEndpoint.staleTimer)
            .sink { [weak self] data, following in
                let (tweets, _, users, media) = data
                do {
                    try ingestRaw(rawTweets: tweets, rawUsers: users, rawMedia: media, following: following)
                    
                    /// Remove tweets from list.
                    for tweet in tweets {
                        inFlight.remove(tweet.id)
                    }
                    NetLog.debug("Follow up has \(inFlight.count) in flight.", print: true, true)
                    
                    let realm = try! Realm()
                    try realm.updateDangling()
                    
                    /// Perform linking and request follow up.
                    let toRecycle = try linkUnlinked()
                    self?.recycle.send(Array(toRecycle))
                    
                    /// Check for further follow up.
                    self?.intake.send()
                } catch {
                    ModelLog.error("\(error)")
                    assert(false, "\(error)")
                }
            }
    }
    
    deinit {
        pipeline?.cancel()
    }
}

public typealias RawData = ([RawHydratedTweet], [RawHydratedTweet], [RawIncludeUser], [RawIncludeMedia])
extension Publisher where Output == [Tweet.ID], Failure == Never {
    func v2Fetch() -> AnyPublisher<RawData, Never> {
        /// - Note: tolerance set to 100% to prevent performance hits.
        /// Docs: https://developer.apple.com/documentation/foundation/timer/1415085-tolerance
        let timer = Timer.publish(every: 0.05, tolerance: 0.05, on: .main, in: .default)
            .autoconnect()
        
        return self
            .flatMap { $0.publisher }
            .buffer(size: UInt(TweetEndpoint.maxResults), timer)
            .filter(\.isNotEmpty)
            /// Only proceed if credentials are loaded.
            .compactMap{ (ids: [Tweet.ID]) -> ([Tweet.ID], OAuthCredentials)? in
                if let credentials = Auth.shared.credentials {
                    return (ids, credentials)
                } else {
                    return nil
                }
            }
            .asyncMap { (ids, credentials) -> ([RawHydratedTweet], [RawHydratedTweet], [RawIncludeUser], [RawIncludeMedia]) in
                do {
                    return try await hydratedTweets(credentials: credentials, ids: ids)
                } catch {
                    NetLog.error("\(error)")
                    assert(false, "\(error)")
                    return ([], [], [], [])
                }
            }
            .eraseToAnyPublisher()
    }
}

/**
 An element in our Combine machinery.
 Dispenses a list of IDs you follow that is guaranteed to be recent.
 */
final class FollowingFetcher<Input, Failure: Error>
    : DeferredBuffer<Input, [User.ID], Failure>
{
    override func _fetch(_ onCompletion: @escaping ([User.ID]) -> Void) {
        Task {
            /// Assume credentials are available.
            let credentials = Auth.shared.credentials!
            
            /// If the fetch fails, fall back on local storage.
            guard let rawUsers = try? await requestFollowing(credentials: credentials) else {
                NetLog.error("Failed to fetch following list!")
                assert(false, "Failed to fetch following list!")
                
                let realm = try! await Realm()
                let ids: [User.ID] = realm.objects(User.self)
                    .filter("\(User.followingPropertyName) == YES")
                    .map(\.id)
                onCompletion(ids)
            }
            
            /// Store fetched results.
            do {
                let realm = try! await Realm()
                try realm.write {
                    /// Remove users who are no longer being followed.
                    realm.followingUsers()
                        .filter { user in
                            /// Find users who were marked as followed but are now missing.
                            rawUsers.contains(where: {user.id == $0.id}) == false
                        }
                        .forEach { user in
                            user.following = false
                        }
                    
                    /// Write all data, including following status, out to disk.
                    rawUsers.forEach { realm.add(User(raw: $0), update: .modified) }
                }
            } catch {
                NetLog.error("Failed to store following list!")
                assert(false, "Failed to store following list!")
            }
            
            /// Call completion handler.
            onCompletion(rawUsers.map(\.id))
        }
    }
}
