//
//  HomeTimelineFetcher.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 23/12/21.
//

import Foundation
import Twig

/**
 Describes an object which helps fetch the home timeline (Twitter v1 API).
 */
internal protocol HomeTimelineFetcher {
    init()
    
    /// Fetch tweets using the provided credentials.
    func fetchTimeline(credentials: OAuthCredentials) async throws -> [RawV1Tweet]
}

/// Helps us fetch Tweets newer than the ones we have.
final class TimelineNewFetcher: HomeTimelineFetcher {
    
    init() {}
    
    func fetchTimeline(credentials: OAuthCredentials) async throws -> [RawV1Tweet] {
        let sinceID = UserDefaults.groupSuite.sinceID
        return try await timeline(credentials: credentials, sinceID: sinceID, maxID: nil)
    }
}

/// Helps us fetch Tweets older than the ones we have.
final class TimelineOldFetcher: HomeTimelineFetcher {
    
    init() {}
    
    func fetchTimeline(credentials: OAuthCredentials) async throws -> [RawV1Tweet] {
        let maxID = UserDefaults.groupSuite.maxID
        return try await timeline(credentials: credentials, sinceID: nil, maxID: maxID)
    }
}
