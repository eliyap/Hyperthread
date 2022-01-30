//
//  HomeTimelineHelper.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 23/12/21.
//

import Foundation
import Twig

/**
 Describes an object which helps fetch the home timeline (Twitter v1 API).
 */
internal protocol HomeTimelineHelper {
    init()
    
    /// Fetch tweets using the provided credentials.
    func fetchTimeline(credentials: OAuthCredentials) async throws -> [RawV1TweetSendable]
}

/// Helps us fetch Tweets newer than the ones we have.
final class TimelineNewFetcher: HomeTimelineHelper {
    
    init() {}
    
    func fetchTimeline(credentials: OAuthCredentials) async throws -> [RawV1TweetSendable] {
        var sinceID = UserDefaults.groupSuite.sinceID
        
        /// Docs: https://developer.twitter.com/en/docs/twitter-api/v1/tweets/timelines/guides/working-with-timelines
        /// > Unlike `max_id` the `since_id` parameter is not inclusive
        /// 
        /// Do avoid disjoint `DateWindow`s, we want a 1-tweet overlap.
        /// Decrementing sinceID effectively re-fetches the most recent tweet.
        if let strID = sinceID, let intID = Int(strID) {
            sinceID = "\(intID - 1)"
        }
        
        return try await timeline(credentials: credentials, sinceID: sinceID, maxID: nil)
    }
}

/// Helps us fetch Tweets older than the ones we have.
final class TimelineOldFetcher: HomeTimelineHelper {
    
    init() {}
    
    func fetchTimeline(credentials: OAuthCredentials) async throws -> [RawV1TweetSendable] {
        /// Docs: https://developer.twitter.com/en/docs/twitter-api/v1/tweets/timelines/guides/working-with-timelines
        /// > ... since the `max_id` parameter is inclusive, the Tweet with the matching ID will actually be returned again
        ///
        /// This is desirable for tracking `DateWindow`, and the overhead should be negligible.
        let maxID = UserDefaults.groupSuite.maxID
        
        return try await timeline(credentials: credentials, sinceID: nil, maxID: maxID)
    }
}
