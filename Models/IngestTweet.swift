//
//  BigFetch.swift
//  BranchRealm
//
//  Created by Secret Asian Man Dev on 31/10/21.
//

import Foundation
import RealmSwift
import Twig

/**
 Accepts raw data from the Twitter v2 API, including `included` tweets,
 */
func ingestRaw(
    rawTweets: [RawHydratedTweet],
    rawUsers: [RawUser],
    rawMedia: [RawIncludeMedia],
    following: [User.ID]
) throws -> Void {
    let realm = try! Realm()
    
    /// Insert all users.
    try realm.write {
        for rawUser in rawUsers {
            let following = following.contains(where: {$0 == rawUser.id})
            let user = User(raw: rawUser, following: following)
            realm.add(user, update: .modified)
        }
    }
    
    /// Reject tweets with missing media (usually happens because they were "included".
    let mediaKeys = rawMedia.map(\.media_key)
    let rawTweets = rawTweets.filter { rawTweet in
        /// If keys exist, check they are all present.
        guard let keys = rawTweet.attachments?.media_keys else { return true }
        return keys.allSatisfy { mediaKeys.contains($0) }
    }
    
    /// Insert Tweets into local database.
    try realm.writeWithToken { token in
        for rawTweet in rawTweets {
            let prior = realm.tweet(id: rawTweet.id)
            
            /// Check `relevance` value in Realm, to avoid ovewriting an existing value (if any).
            let checkedRelevance = prior?.relevance ?? Relevance(tweet: rawTweet, following: following)
            
            /// Check for existing`read`. If none, mark read if this is the first run.
            let checkedRead = prior?.read ?? UserDefaults.groupSuite.firstFetch
            
            let tweet: Tweet = Tweet(raw: rawTweet, rawMedia: rawMedia, relevance: checkedRelevance, read: checkedRead)
            
            realm.add(tweet, update: .modified)
            
            /// Safety check: we count on the user never being missing!
            if realm.user(id: rawTweet.author_id) == nil {
                fatalError("Could not find user with id \(rawTweet.author_id)")
            }
            
            /// Attach to conversation (create one if necessary).
            realm.linkConversation(token, tweet: tweet)
        }
    }
}

/**
 Accepts raw data from the Twitter v2 API.
 - Warning: Do not feed `include`d `Tweet`s!
            These may be missing media keys, or be of a different `Relevance` than the main payload!
 */
func ingestRaw(
    rawTweets: [RawHydratedTweet],
    rawUsers: [RawUser],
    rawMedia: [RawIncludeMedia],
    relevance: Relevance
) throws -> Void {
    let realm = try! Realm()
    
    /// Insert all users.
    try realm.write {
        for rawUser in rawUsers {
            /// Check `following` status in Realm, to avoid ovewriting an existing value (if any).
            let following = realm.user(id: rawUser.id)?.following ?? false
            
            let user = User(raw: rawUser, following: following)
            realm.add(user, update: .modified)
        }
    }
    
    /// Insert Tweets into local database.
    try realm.writeWithToken { token in
        for rawTweet in rawTweets {
            /// Check for existing`read`. If none, mark read if this is the first run.
            let checkedRead = realm.tweet(id: rawTweet.id)?.read ?? UserDefaults.groupSuite.firstFetch
            
            /// - Note: **intentionally** overwrite existing `relevance`, which may have resulted
            ///         from user timeline fetch.
            let tweet: Tweet = Tweet(raw: rawTweet, rawMedia: rawMedia, relevance: relevance, read: checkedRead)
            realm.add(tweet, update: .modified)
            
            /// Safety check: we count on the user never being missing!
            if realm.user(id: rawTweet.author_id) == nil {
                fatalError("Could not find user with id \(rawTweet.author_id)")
            }
            
            /// Attach to conversation (create one if necessary).
            realm.linkConversation(token, tweet: tweet)
        }
    }
}

internal func linkUnlinked() throws -> Set<Tweet.ID> {
    var idsToFetch = Set<Tweet.ID>()
    
    let realm = try! Realm()
    
    /// Check unlinked conversations.
    let unlinked = realm.objects(Conversation.self)
        .filter(NSPredicate(format: "\(Conversation.discussionPropertyName).@count == 0"))
    try realm.writeWithToken { token in
        for conversation in unlinked {
            link(token, conversation: conversation, idsToFetch: &idsToFetch, realm: realm)
        }
    }
    
    return idsToFetch
}

/// Tries to link Tweets to Conversations, and Conversations to Discussions.
fileprivate func link(
    _ token: Realm.TransactionToken,
    conversation: Conversation,
    idsToFetch: inout Set<Tweet.ID>, realm: Realm
) -> Void {
    /// Link to upstream's discussion, if possible.
    if
        let upstreamID = conversation.upstream,
        let upstreamConvo = realm.conversation(id: upstreamID),
        let upstream: Discussion = upstreamConvo.discussion.first
    {
        upstream.insert(conversation, token, realm: realm)
        return
    }
    /** Conclusion: upstream is either missing, or itself has no `Discussion`. **/
    
    /// Link the conversation to a local tweet, if needed and possible.
    if
        conversation.root == nil,
        let local = realm.tweet(id: conversation.id)
    {
        conversation.root = local
    }
    
    /// Check if root tweet was still not found.
    guard let root: Tweet = conversation.root else {
        idsToFetch.insert(conversation.id)
        return
    }
    
    /// Remove conversations that are standalone discussions.
    guard let rootPRID: Tweet.ID = root.primaryReference else {
        /// Since the `root` has no references, its conversation is the `Discussion.root`.
        /// Recognize the conversation as its own discussion.
        conversation.upstream = root.id
        realm.add(Discussion(root: conversation))
        
        return
    }
    
    /// Remove conversations with un-fetched upstream tweets.
    guard let rootPrimaryReference: Tweet = realm.tweet(id: rootPRID) else {
        /// Go fetch the upstream reference.
        idsToFetch.insert(rootPRID)
        return
    }
    
    /// Set upstream conversation.
    let upstreamID: Conversation.ID = rootPrimaryReference.conversation_id
    conversation.upstream = upstreamID
        
    /// Check if the upstream Conversation is part of a Discussion.
    if
        let upstreamConvo = realm.conversation(id: upstreamID),
        let upstream: Discussion = upstreamConvo.discussion.first
    {
        upstream.insert(conversation, token, realm: realm)
    } else {
        /// Otherwise, fetch the upstream Conversation's root Tweet.
        idsToFetch.insert(upstreamID)
    }
}
