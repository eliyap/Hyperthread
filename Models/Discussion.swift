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
    
    @Persisted(primaryKey: true)
    var id: ID
    typealias ID = Tweet.ID
    
    @Persisted
    var root: Conversation?
    
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
    }
}

extension Discussion {
    var tweets: [Tweet] {
        conversations.flatMap(\.tweets)
    }
}

extension Discussion {
    func relevantTweets(followingUserIDs: [String]) -> [Tweet] {
        let tweets = self.tweets
        var result = Set<Tweet>()

        /// Include tweets from following users.
        var followingTweets = [Tweet]()
        for tweet in tweets {
            if followingUserIDs.contains(tweet.user.first!.id) {
                followingTweets.append(tweet)
            }
        }
        result.formUnion(followingTweets)
        
        /// Include tweets that they referenced.
        var refIDs = Set<Tweet.ID>()
        for tweet in followingTweets {
            refIDs.formUnion(tweet.referenced)
        }
        result.formUnion(refIDs.map{ id in tweets.first(where: {id == $0.id})!})
        
        return result.sorted(by: {$0.id < $1.id})
    }
}
