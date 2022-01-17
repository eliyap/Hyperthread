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
            if let replyID = tweet.replying_to {
                if self.tweet(id: replyID) != nil {
                    tweet.dangling.remove(.reply)
                }
            } else {
                ModelLog.error("Illegal State! Reply ID missing!")
                assert(false)
            }
        }

        if tweet.dangling.contains(.quote) {
            if let quoteID = tweet.quoting {
                if self.tweet(id: quoteID) != nil {
                    tweet.dangling.remove(.quote)
                }
            } else {
                ModelLog.error("Illegal State! Quote ID missing!")
                assert(false)
            }
        }

        if tweet.dangling.contains(.retweet) {
            if let retweetID = tweet.retweeting { 
                if self.tweet(id: retweetID) != nil {
                    tweet.dangling.remove(.retweet)
                }
            } else {
                ModelLog.error("Illegal State! Retweet ID missing!")
                assert(false)
            }
        }
    }
}
