//
//  MakeUnavailable.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 15/1/22.
//

import Foundation
import RealmSwift

extension Realm {
    /// Remove all references to this `Tweet.ID`, because it is not available from Twitter.
    /// Typically this is due to the `Tweet` being deleted or the account being private.
    func makeUnavailable(_ token: TransactionToken, id: Tweet.ID) -> Void {
        let replies = objects(Tweet.self)
            .where { $0.replying_to == id }
        let quotes = objects(Tweet.self)
            .where { $0.quoting == id }
        let retweets = objects(Tweet.self)
            .where { $0.retweeting == id }
        
        replies.forEach {
            $0.replying_to = nil
            $0.dangling.remove(.reply)
        }
        quotes.forEach {
            $0.quoting = nil
            $0.dangling.remove(.quote)
        }
        retweets.forEach {
            $0.retweeting = nil
            $0.dangling.remove(.retweet)
        }
    }
}
