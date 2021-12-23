//
//  HomeIngest.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 23/12/21.
//

import Foundation
import Combine
import RealmSwift
import Twig

internal protocol HomeTimelineFetcher {
    init()
    func fetchTimeline(credentials: OAuthCredentials) async throws -> [RawV1Tweet]
    func updateBoundaries(tweets: [Tweet]) -> Void
}

final class TimelineNewFetcher: HomeTimelineFetcher {
    
    init() {}
    
    func fetchTimeline(credentials: OAuthCredentials) async throws -> [RawV1Tweet] {
        let sinceID = UserDefaults.groupSuite.sinceID
        return try await timeline(credentials: credentials, sinceID: sinceID, maxID: nil)
    }
    
    func updateBoundaries(tweets: [Tweet]) {
        /// Update home timeline boundaries.
        let sinceID = UserDefaults.groupSuite.sinceID
        let newSinceID = max(Int64?(tweets.map(\.id).min()), Int64?(sinceID))
        UserDefaults.groupSuite.sinceID = newSinceID.string
        NetLog.debug("new SinceID: \(newSinceID ?? 0), previously \(sinceID ?? "nil")")
    }
}

final class TimelineOldFetcher: HomeTimelineFetcher {
    
    init() {}
    
    func fetchTimeline(credentials: OAuthCredentials) async throws -> [RawV1Tweet] {
        let maxID = UserDefaults.groupSuite.maxID
        return try await timeline(credentials: credentials, sinceID: nil, maxID: maxID)
    }
    
    func updateBoundaries(tweets: [Tweet]) {
        /// Update home timeline boundaries.
        let maxID = UserDefaults.groupSuite.maxID
        let newMaxID = min(Int64?(tweets.map(\.id).min()), Int64?(maxID))
        UserDefaults.groupSuite.maxID = newMaxID.string
        NetLog.debug("new MaxID: \(newMaxID ?? 0), previously \(maxID ?? "nil")")
    }
}


final class HomeIngest<T: HomeTimelineFetcher> {
    
    private let pipeline: AnyCancellable
    public let intake = PassthroughSubject<Void, Never>()
    
    /// - Note: tolerance set to 100% to prevent performance hits.
    /// Docs: https://developer.apple.com/documentation/foundation/timer/1415085-tolerance
    private let timer = Timer.publish(every: 0.05, tolerance: 0.05, on: .main, in: .default)
        .autoconnect()
    
    public init() {
        let fetcher = T()
        
        /// When requested, publishes the IDs of new tweets on the home timeline.
        let timelineIDPublisher: AnyPublisher<[Tweet.ID], Never> = intake
            /// Only proceed if credentials are loaded.
            .compactMap { Auth.shared.credentials }
            .asyncMap { (credentials) -> [RawV1Tweet] in
                do {
                    return try await fetcher.fetchTimeline(credentials: credentials)
                } catch {
                    NetLog.error("\(error)")
                    assert(false, "\(error)")
                    return []
                }
            }
            .flatMap { $0.publisher }
            .map { (raw: RawV1Tweet) in
                "\(raw.id)"
            }
            .buffer(size: UInt(TweetEndpoint.maxResults), timer)
            .filter(\.isNotEmpty)
            .eraseToAnyPublisher()
        
        pipeline = timelineIDPublisher
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
            .sink(receiveValue: { (tweets, _, users, media) in
                do {
                    try ingestRaw(rawTweets: tweets, rawUsers: users, rawMedia: media, relevance: .discussion)
                    
                    /// Update home timeline boundaries.
                    let maxID = UserDefaults.groupSuite.maxID
                    let newMaxID = min(Int64?(tweets.map(\.id).min()), Int64?(maxID))
                    UserDefaults.groupSuite.maxID = newMaxID.string
                    NetLog.debug("new MaxID: \(newMaxID ?? 0), previously \(maxID ?? "nil")")
                } catch {
                    ModelLog.error("\(error)")
                    assert(false, "\(error)")
                }
            })
    }
}
