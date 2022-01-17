//
//  UpdateRelevance.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 17/1/22.
//

import Foundation
import RealmSwift

/// When a user is followed / unfollowed, we show / hide their tweets by updating the "relevance" metric.
extension Realm {
    func updateRelevanceOnFollow(_ token: TransactionToken, userID: User.ID) -> Void {
        let usersTweets = objects(Tweet.self)
            .filter(NSPredicate(format: "\(Tweet.authorIDPropertyName) == %@", userID))
        
        /// Check that returned set is non-empty.
        ModelLog.debug("Setting relevance for \(usersTweets.count) tweets.", print: true, true)
        
        /// Update all relevance metrics.
        for tweet in usersTweets {
            tweet.relevance = .init(tweet: tweet, following: [userID])
        }
    }
    
    func updateRelevanceOnUnfollow(_ token: TransactionToken, userID: User.ID) -> Void {
        let usersTweets = objects(Tweet.self)
            .filter(NSPredicate(format: "\(Tweet.authorIDPropertyName) == %@", userID))
        
        /// Update all relevance metrics.
        for tweet in usersTweets {
            tweet.relevance = .irrelevant
        }
    }
}
