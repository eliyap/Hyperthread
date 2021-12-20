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
    var tweets: List<Tweet> {
        /// Invalidate value.
        didSet { _maxRelevance = nil }
    }
    public static let tweetsPropertyName = "tweets"
    
    /**
     A SQL-Query friendly variable which exposes the maximum relevance in `tweets`.
     Invalidated whenever `tweets` is modified by setting the stored value to `nil`.
     */
    @Persisted
    private var _maxRelevance: Relevance.RawValue? = nil
    public var maxRelevance: Relevance! {
        get {
            if let raw = _maxRelevance {
                return .init(rawValue: raw)
            } else if tweets.isNotEmpty {
                /// Find and memoize result.
                let max = tweets.map(\.relevance).max()!
                _maxRelevance = max.rawValue
                return max
            } else {
                return .irrelevant
            }
        }
        /** Should never be `set`. **/
    }

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
