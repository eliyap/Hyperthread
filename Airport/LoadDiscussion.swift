//
//  LoadDiscussion.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 29/1/22.
//

import Foundation
import Twig
import RealmSwift

/// Load a discussion around a specific tweet ID.
internal func fetchDiscussion(tweetID: Tweet.ID) async throws -> Discussion {
    await ReferenceCrawler.shared.fetchSingle(id: tweetID)
    let realm: Realm = makeRealm()
    guard let tweet = makeRealm().tweet(id: tweetID) else {
        throw TweetLookupError.couldNotFindTweet
    }
    
    /// Temporarily elevate relevance.
    let originalRelevance = tweet.relevance
    try realm.writeWithToken { token in
        tweet.relevance = .discussion
    }
    
    await ReferenceCrawler.shared.performFollowUp()
    guard
        let conversation = tweet.conversation.first,
        let discussion = conversation.discussion.first
    else {
        throw TweetLookupError.couldNotFindTweet
    }
    
    return discussion
}
