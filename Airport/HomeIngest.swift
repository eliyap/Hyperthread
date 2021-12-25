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

final class HomeIngest<T: HomeTimelineFetcher> {
    
    private let pipeline: AnyCancellable
    public let intake = PassthroughSubject<Void, Never>()
    
    /// - Note: tolerance set to 100% to prevent performance hits.
    /// Docs: https://developer.apple.com/documentation/foundation/timer/1415085-tolerance
    private let timer = Timer.publish(every: 0.05, tolerance: 0.05, on: .main, in: .default)
        .autoconnect()
    
    weak var followUp: FollowUp?
    
    public init(followUp: FollowUp) {
        self.followUp = followUp
        
        let fetcher = T()
        
        /// When requested, publishes the IDs of new tweets on the home timeline.
        self.pipeline = intake
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
            .map { $0.map{ "\($0.id)" } }
            .v2Fetch()
            /// Synchronize
            .receive(on: Airport🆕.scheduler)
            .sink(receiveValue: { (tweets, _, users, media) in
                do {
                    try ingestRaw(rawTweets: tweets, rawUsers: users, rawMedia: media, relevance: .discussion)
                    
                    /// Update home timeline boundaries.
                    fetcher.updateBoundaries(tweets: tweets)
                    
                    followUp.intake.send()
                } catch {
                    ModelLog.error("\(error)")
                    assert(false, "\(error)")
                }
            })
    }
    
    deinit {
        pipeline.cancel()
    }
}
