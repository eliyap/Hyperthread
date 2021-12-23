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
    private let pipeline: AnyCancellable
    public let intake = PassthroughSubject<Void, Never>()
    
    /// - Note: tolerance set to 100% to prevent performance hits.
    /// Docs: https://developer.apple.com/documentation/foundation/timer/1415085-tolerance
    private let timer = Timer.publish(every: 0.05, tolerance: 0.05, on: .main, in: .default)
        .autoconnect()
    
    init() {
        var inFlight: Set<Tweet.ID> = []
        let timelineIDPublisher: AnyPublisher<[Tweet.ID], Never> = intake
            .map { (_) -> Set<Tweet.ID> in
                let realm = try! Realm()
                var toFetch: Set<Tweet.ID> = []
                
                let c = realm.conversationsWithFollowUp()
                    .map { $0.getFollowUp(realm: realm) }
                    .reduce(Set<Tweet.ID>()) { $0.union($1) }
                toFetch.formUnion(c)
                
                let d = realm.discussionsWithFollowUp()
                    .map { $0.getFollowUp(realm: realm) }
                    .reduce(Set<Tweet.ID>()) { $0.union($1) }
                toFetch.formUnion(d)
                
                print(realm.conversationsWithFollowUp().count)
                print(realm.discussionsWithFollowUp().count)
                return toFetch
            }
            .flatMap({
                Array($0).publisher
            })
            .filter { inFlight.contains($0) == false }
            .map { (id: Tweet.ID) -> Tweet.ID in
                inFlight.insert(id)
                print(id)
                return id
            }
            .buffer(size: UInt(TweetEndpoint.maxResults), timer)
            .filter(\.isNotEmpty)
            .eraseToAnyPublisher()
        
        self.pipeline = timelineIDPublisher
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
                    return try await _hydratedTweets(credentials: credentials, ids: ids)
                } catch {
                    NetLog.error("\(error)")
                    assert(false, "\(error)")
                    return ([], [], [], [])
                }
            }
            .sink { _ in
                
            }
    }
    
    deinit {
        pipeline.cancel()
    }
}

extension Publisher where Output == [Tweet.ID], Failure == Never {
    typealias RawData = ([RawHydratedTweet], [RawHydratedTweet], [RawIncludeUser], [RawIncludeMedia])
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
                    return try await _hydratedTweets(credentials: credentials, ids: ids)
                } catch {
                    NetLog.error("\(error)")
                    assert(false, "\(error)")
                    return ([], [], [], [])
                }
            }
            .eraseToAnyPublisher()
    }
}
