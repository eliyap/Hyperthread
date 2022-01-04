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

final class FollowUp: Conduit<Void, Never> {
    /// Conduit Object with which to request user objects.
    private weak var userFetcher: UserFetcher?
    
    /// An additional "intake" for follow up on follow up.
    public let recycle = PassthroughSubject<[Tweet.ID], Never>()
    
    init(userFetcher: UserFetcher) {
        self.userFetcher = userFetcher
        super.init()
        var inFlight: Set<Tweet.ID> = []
        
        let intakePublisher = intake
            /// Synchronize
            .receive(on: Airport.scheduler)
            .map { (_) -> Set<Tweet.ID> in
                let realm = try! Realm()
                var toFetch: Set<Tweet.ID> = []
                
                let c = realm.conversationsWithFollowUp()
                toFetch.formUnion(c
                    .map { $0.getFollowUp(realm: realm) }
                    .reduce(Set<Tweet.ID>()) { $0.union($1) }
                )
                
                let d = realm.discussionsWithFollowUp()
                toFetch.formUnion(d
                    .map { $0.getFollowUp() }
                    .reduce(Set<Tweet.ID>()) { $0.union($1) }
                )
                
                NetLog.debug("\(c.count) conversations, \(d.count) discussions requiring follow up.", print: true, true)
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
            .asyncMap { rawData -> (RawData, FollowingCache.Output) in
                let followingIDs = await FollowingCache.shared.request()
                return (rawData, followingIDs)
            }
            .sink { [weak self] data, following in
                let (tweets, included, users, media) = data
                do {
                    /// Safe to insert `included`, as we make no assumptions around `Relevance`.
                    try ingestRaw(rawTweets: tweets + included, rawUsers: users, rawMedia: media, following: following)
                    
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
                } catch {
                    ModelLog.error("\(error)")
                    assert(false, "\(error)")
                }
                
                /// Check for further follow up.
                self?.intake.send()
                
                let missingUsers = findMissingMentions(tweets: tweets, users: users)
                for userID in missingUsers {
                    self?.userFetcher?.intake.send(userID)
                }
            }
    }
}

public typealias RawData = ([RawHydratedTweet], [RawHydratedTweet], [RawUser], [RawIncludeMedia])
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
            .asyncMap { (ids, credentials) -> ([RawHydratedTweet], [RawHydratedTweet], [RawUser], [RawIncludeMedia]) in
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
