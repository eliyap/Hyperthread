//
//  Conversation.swift
//  BranchRealm
//
//  Created by Secret Asian Man Dev on 31/10/21.
//

import Foundation
import RealmSwift
import Realm
import Twig

/**
 Represents a Twitter Conversation, as identified by a conversation ID in the v2 API.
 Part of a Branch "Discussion".
 */
final class Conversation: Object, Identifiable {
    
    @Persisted(originProperty: Discussion.conversationsPropertyName)
    var discussion: LinkingObjects<Discussion>
    public static let discussionPropertyName = "discussion"
    
    /// The tweet ID corresponsing to the conversation's start.
    @Persisted(primaryKey: true)
    var id: ID
    typealias ID = Tweet.ID
    
    /// Refers to the "upstream conversation", that is
    /// the conversation ID which ``Root`` is referencing, if any.
    /// If none, `upstream` should be set equal to `id`.
    /// `nil` indicates the need to fetch.
    @Persisted
    var upstream: ID?
    
    @Persisted
    var root: Tweet?
    
    @Persisted
    var tweets: List<Tweet>
    public static let tweetsPropertyName = "tweets"

    init(id: String) {
        super.init()
        self.id = id
        self.tweets = List<Tweet>()
    }

    override required init() {
        super.init()
    }
}

extension Conversation {
    public func insert(_ tweet: Tweet) {
        /// Insert tweet if missing.
        if tweets.contains(where: {$0.id == tweet.id}) == false {
            tweets.append(tweet)
        }
        
        /// Check is root tweet.
        if tweet.id == self.id {
            root = tweet
        }
    }
}
