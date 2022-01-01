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

final class HomeIngest<Fetcher: HomeTimelineFetcher>: Conduit<Void, Never> {
    
    /// - Note: tolerance set to 100% to prevent performance hits.
    /// Docs: https://developer.apple.com/documentation/foundation/timer/1415085-tolerance
    private let timer = Timer.publish(every: 0.05, tolerance: 0.05, on: .main, in: .default)
        .autoconnect()
    
    /// Conduit Object with which to request follow up fetches.
    weak var followUp: FollowUp?
    
    /// Conduit Object with which to request user timeline fetches.
    weak var timelineConduit: TimelineConduit?
    
    /// Completion handlers to be executed and discarded when a fetch completes successfully.
    private var onFetched: [() -> Void] = []
    
    public init(followUp: FollowUp, timelineConduit: TimelineConduit) {
        super.init()
        self.followUp = followUp
        self.timelineConduit = timelineConduit
        
        let fetcher = Fetcher()
        
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
            /// Convert to strings
            .map { [weak self] ids in
                /// Fire completion early if home timeline returns nothing.
                /// This prevents the "empty" filter in `v2Fetch` from swallowing stuff.
                if ids.isEmpty {
                    self?.removeAll()
                }
                return ids.map{ "\($0.id)" }
            }
            .v2Fetch()
            /// Synchronize
            .receive(on: Airport.scheduler)
            .sink(receiveValue: { [weak self] (tweets, _, users, media) in
                do {
                    NetLog.debug("Received \(tweets.count) home timeline tweets.", print: true, true)
                    try ingestRaw(rawTweets: tweets, rawUsers: users, rawMedia: media, relevance: .discussion)
                    
                    /// Update home timeline boundaries.
                    self?.updateBoundaries(tweets: tweets)
                    
                    /// Update user date window target, request based on expanded window.
                    UserDefaults.groupSuite.expandUserTimelineWindow(tweets: tweets)
                    timelineConduit.intake.send()
                    
                    /// Immediately check for follow up.
                    followUp.intake.send()
                    
                    timelineConduit.intake.send()
                    
                    self?.removeAll()
                } catch {
                    ModelLog.error("\(error)")
                    assert(false, "\(error)")
                }
            })
    }
    
    public func add(_ completion: @escaping () -> Void) -> Void {
        onFetched.append(completion)
    }
    
    private func removeAll() -> Void {
        /// Execute and remove completion handlers.
        onFetched.forEach { $0() }
        onFetched = []
    }
    
    /// Update home timeline ID boundaries.
    fileprivate func updateBoundaries(tweets: [TweetIdentifiable]) -> Void {
        let sinceID = UserDefaults.groupSuite.sinceID
        let tweetsMaxID = tweets.compactMap { Int64($0.id) }.max()
        let newSinceID = max(tweetsMaxID, Int64?(sinceID))
        UserDefaults.groupSuite.sinceID = newSinceID.string
        NetLog.debug("new SinceID: \(newSinceID ?? 0), previously \(sinceID ?? "nil")")
        
        /// Update home timeline boundaries.
        let maxID = UserDefaults.groupSuite.maxID
        let tweetsMinID = tweets.compactMap { Int64($0.id) }.min()
        let newMaxID = min(tweetsMinID, Int64?(maxID))
        UserDefaults.groupSuite.maxID = newMaxID.string
        NetLog.debug("new MaxID: \(newMaxID ?? 0), previously \(maxID ?? "nil")")
    }
}
