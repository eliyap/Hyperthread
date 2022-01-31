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
    if let discussionID = tweet.discussionID {
        return discussionID
    }
    
    /// Temporarily elevate relevance.
    let originalRelevance = tweet.relevance
    let realm = makeRealm()
    try realm.writeWithToken { token in
        realm.tweet(id: tweet.id)?.relevance = .discussion
    }
    defer {
        do {
            let resetRealm = makeRealm()
            try resetRealm.writeWithToken { token in
                resetRealm.tweet(id: tweet.id)?.relevance = originalRelevance
            }
        } catch {
            Logger.general.error("Failed to reset relevance")
        }
    }
    
    await ReferenceCrawler.shared.performFollowUp()
    
    return try { /// Synchronous context.
        let r = makeRealm()
        guard
            let t = r.tweet(id: tweet.id),
            let c = t.conversation.first,
            let d = c.discussion.first
        else { throw TweetLookupError.couldNotFindTweet }
        
        return d.id
    }()
}

fileprivate func getTweet(id: Tweet.ID) async throws -> TweetModel {
    /// Check local storage first.
    if let local = makeRealm().tweet(id: id) {
        return .init(tweet: local)
    } else {
        await ReferenceCrawler.shared.fetchSingle(id: id)
        guard let tweet = makeRealm().tweet(id: id) else {
            throw TweetLookupError.couldNotFindTweet
        }
        return .init(tweet: tweet)
    }
}

fileprivate struct TweetModel {
    let id: Tweet.ID
    let relevance: Relevance
    let conversationID: Conversation.ID?
    let discussionID: Discussion.ID?
    
    init(tweet: Tweet) {
        self.id = tweet.id
        self.relevance = tweet.relevance
        self.conversationID = tweet.conversation.first?.id
        self.discussionID = tweet.conversation.first?.discussion.first?.id
    }
}
