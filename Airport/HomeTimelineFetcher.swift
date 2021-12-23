//
//  HomeTimelineFetcher.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 23/12/21.
//

import Foundation
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
