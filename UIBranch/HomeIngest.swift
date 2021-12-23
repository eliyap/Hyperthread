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

final class HomeIngestNew {
    
    private let pipeline: AnyCancellable
    public let intake = PassthroughSubject<Void, Never>()
    
    /// - Note: tolerance set to 100% to prevent performance hits.
    /// Docs: https://developer.apple.com/documentation/foundation/timer/1415085-tolerance
    private let timer = Timer.publish(every: 0.05, tolerance: 0.05, on: .main, in: .default)
        .autoconnect()
    
    public init() {
        /// When requested, publishes the IDs of new tweets on the home timeline.
        let timelineIDPublisher: AnyPublisher<[Tweet.ID], Never> = intake
            /// Only proceed if credentials are loaded.
            .compactMap { Auth.shared.credentials }
            .asyncMap { (credentials) -> [RawV1Tweet] in
                let sinceID = UserDefaults.groupSuite.sinceID
                do {
                    return try await timeline(credentials: credentials, sinceID: sinceID, maxID: nil)
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
