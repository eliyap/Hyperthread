//
//  LoadDiscussion.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 29/1/22.
//

import Foundation
import Twig
import RealmSwift
import BlackBox

/// Load a discussion around a specific tweet ID.
internal func fetchDiscussion(tweetID: Tweet.ID) async throws -> Discussion.ID {
    let tweet = try await getTweet(id: tweetID)
    
    /// Check if discussion already exists.
    if
        let conversation = tweet.conversation.first,
        let discussion = conversation.discussion.first
    {
        return discussion.id
    }
    
    /// Temporarily elevate relevance.
    let originalRelevance = tweet.relevance
    try makeRealm().writeWithToken { token in
        tweet.relevance = .discussion
    }
    defer {
        do {
            try makeRealm().writeWithToken { token in
                tweet.relevance = originalRelevance
            }
        } catch {
            Logger.general.error("Failed to reset relevance")
        }
    }
    
    await ReferenceCrawler.shared.performFollowUp()
    guard
        let conversation = tweet.conversation.first,
        let discussion = conversation.discussion.first
    else {
        throw TweetLookupError.couldNotFindTweet
    }
    
    return discussion.id
}

fileprivate func getTweet(id: Tweet.ID) async throws -> Tweet {
    /// Check local storage first.
    if let local = makeRealm().tweet(id: id) {
        return local
    } else {
        await ReferenceCrawler.shared.fetchSingle(id: id)
        guard let tweet = makeRealm().tweet(id: id) else {
            throw TweetLookupError.couldNotFindTweet
        }
        return tweet
    }
}
