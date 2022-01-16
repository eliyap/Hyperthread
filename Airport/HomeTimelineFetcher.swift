//
//  HomeTimelineFetcher.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 16/1/22.
//

import Foundation
import RealmSwift
import Twig

internal struct HomeTimelineFetcher<Helper: HomeTimelineHelper> {
    
    /// Realm observation tokens to ignore.
    private let tokens: [NotificationToken]
    
    init(doNotNotify tokens: [NotificationToken]) {
        self.tokens = tokens
    }
    
    /// - Note: also dispatches User Timeline requests.
    internal func homeTimelineFetch<Fetcher: HomeTimelineHelper>(_: Fetcher.Type) async throws -> Void {
        let fetcher = Fetcher()
        guard let credentials = Auth.shared.credentials else { throw UserError.credentials }
        let v1Tweets: [RawV1Tweet]
        do {
            v1Tweets = try await fetcher.fetchTimeline(credentials: credentials)
        } catch {
            NetLog.error("\(error)")
            assert(false)
            throw UserError.fetch(error)
        }
        
        /// Dispatch user timeline request in parallel, since we can infer the desired range.
        Task {
            if v1Tweets.isNotEmpty {
                await fetchTimelines(window: .init(
                    start: v1Tweets.map(\.created_at).min()!,
                    end: v1Tweets.map(\.created_at).max()!
                ))
            }
        }
        
        /// Dispatch chunk requests in parallel.
        await withTaskGroup(of: Void.self) { group in
            let ids = v1Tweets.map {"\($0.id)"}
            ids.chunks(ofCount: TweetEndpoint.maxResults).forEach { chunk in
                group.addTask {
                    do {
                        let rawData = try await hydratedTweets(credentials: credentials, ids: Array(chunk))
                        try store(rawData: rawData)
                    } catch {
                        NetLog.error("\(error)")
                        assert(false)
                    }
                }
            }
            
            /// Ensure all chunk requests complete before returning.
            await group.waitForAll()
        }
        
        /// - Note: deliberate choice to *not* perform follow up here.
    }

    /// Perform local storage work after network fetch.
    fileprivate func store(rawData: RawData) throws -> Void {
        let (tweets, _, users, media) = rawData
        NetLog.debug("Received \(tweets.count) home timeline tweets.", print: true, true)
        
        try ingestRaw(withoutNotifying: self.tokens, rawTweets: tweets, rawUsers: users, rawMedia: media, relevance: .discussion)
        
        /// Update home timeline boundaries.
        /// - Note: use v2 tweets *after storage*, not v1 tweets, to be *sure* storage was successful.
        updateBoundaries(tweets: tweets)
        
        /// Update user date window target, request based on expanded window.
        UserDefaults.groupSuite.expandUserTimelineWindow(tweets: tweets)
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
