//
//  UpdateDangling.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 17/1/22.
//

import Foundation
import RealmSwift

extension Realm {
    /// Update the "dangling reference" status of Tweets that are marked as having them.
    internal func updateDangling() throws -> Void {
        let tweets = objects(Tweet.self)
            .filter(.init(format: "\(Tweet.danglingPropertyName) > 0"))
        
        /// Do a just-in-time check for tweets which are no longer dangling.
        try writeWithToken { token in
            for tweet in tweets {
                updateReferenceSet(token, tweet: tweet)
            }
        }
    }
}

extension Realm {
    /// Update `Tweet`'s reference set based on what is present in the database.
    fileprivate func updateReferenceSet(_ token: TransactionToken, tweet: Tweet) -> Void {
        if tweet.dangling.contains(.reply) {
            guard let replyID = tweet.replying_to else {
                ModelLog.error("Illegal State! Reply ID missing!")
                assert(false)
                return
            }
            if self.tweet(id: replyID) != nil {
                tweet.dangling.remove(.reply)
            }
        }

        if tweet.dangling.contains(.quote) {
            guard let quoteID = tweet.quoting else {
                ModelLog.error("Illegal State! Quote ID missing!")
                assert(false)
                return
            }
            if self.tweet(id: quoteID) != nil {
                tweet.dangling.remove(.quote)
            }
        }

        if tweet.dangling.contains(.retweet) {
            guard let retweetID = tweet.retweeting else {
                ModelLog.error("Illegal State! Retweet ID missing!")
                assert(false)
                return
            }
            if self.tweet(id: retweetID) != nil {
                tweet.dangling.remove(.retweet)
            }
        }
    }
}
