//
//  Discussion.swift
//  BranchRealm
//
//  Created by Secret Asian Man Dev on 31/10/21.
//

import Foundation
import RealmSwift
import Realm
import Twig

final class Discussion: Object, Identifiable {
    
    /// The root conversation ID, and thereby the root Tweet ID.
    @Persisted(primaryKey: true)
    var id: ID
    typealias ID = Tweet.ID
    
    @Persisted
    var root: Conversation?
    
    /// The `createdAt` date of the most recent Tweet in this Discussion.
    @Persisted
    var updatedAt: Date
    
    @Persisted
    var conversations: List<Conversation>
    public static let conversationsPropertyName = "conversations"
    
    override required init() {
        super.init()
    }

    init(root: Conversation) {
        super.init()
        self.id = root.id
        self.root = root
        self.conversations = List<Conversation>()
        self.conversations.append(root)
        
        /// Safe to force unwrap, `root` must have ≥1 `tweets`.
        self.updatedAt = root.tweets.map(\.createdAt).max()!
    }
}

extension Discussion {
    var tweets: [Tweet] {
        conversations.flatMap(\.tweets)
    }
}

extension Discussion {
    func relevantTweets(followingUserIDs: [String]?) -> [Tweet] {
        let tweets = self.tweets
        guard let followingUserIDs = followingUserIDs else { 
            Swift.debugPrint("No followingUserIDs, returning list unaltered.")
            return tweets 
        }
        var result = Set<Tweet>()

        /// Include tweets from following users.
        var followingTweets = [Tweet]()
        for tweet in tweets {
            if followingUserIDs.contains(tweet.authorID) {
                followingTweets.append(tweet)
            }
        }
        result.formUnion(followingTweets)
        
        /// Include tweets that they referenced.
        var refIDs = Set<Tweet.ID>()
        for tweet in followingTweets {
            refIDs.formUnion(tweet.referenced)
        }
        let refTweets: [Tweet] = refIDs.compactMap { id in
            if let tweet = tweets.first(where: {id == $0.id}) {
                return tweet
            } else {
                Swift.debugPrint("Referenced tweet not in discussion with id \(id)")
                return nil
            }
        }
        result.formUnion(refTweets)
        
        /// Remove retweets, but add an ephemeral mark for displaying.
        var toRemove = Set<Tweet>()
        for tweet in result {
            if let rtID = tweet.retweeting {
                toRemove.insert(tweet)
                let retweeted = tweets.first(where: {$0.id == rtID})!
                retweeted.retweetedBy.insert(tweet.authorID)
            }
        }
        result.formSymmetricDifference(toRemove)
        
        return result.sorted(by: {$0.id < $1.id})
    }
}

extension Discussion {
    /// Update the last updated date.
    func update(with date: Date?) -> Void {
        if let date = date {
            updatedAt = max(updatedAt, date)
        }
    }
}
