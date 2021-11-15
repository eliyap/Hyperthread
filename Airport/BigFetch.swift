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
 Accepts raw data from the Twitter v2 API.
 Returns: Tweet IDs still need to be fetched.
 Also tries to link Tweets to Conversations, and Conversations to Discussions.
 */
func furtherFetch(rawTweets: [RawHydratedTweet], rawUsers: [RawIncludeUser]) throws -> Set<Tweet.ID> {
    let realm = try! Realm()
    
    /// IDs for further fetching.
    var idsToFetch = Set<Tweet.ID>()
    
    var tweets = Set<Tweet>()
    var users = Set<User>()
    
    /// Insert all users.
    try realm.write {
        for rawUser in rawUsers {
            let user = User(raw: rawUser)
            realm.add(user, update: .modified)
            users.insert(user)
        }
    }
    
    /// Insert Tweets into local database.
    try realm.write {
        for rawTweet in rawTweets {
            let tweet: Tweet = Tweet(raw: rawTweet)
            realm.add(tweet, update: .modified)
            tweets.insert(tweet)
            
            /// Attach to user.
            guard let user: User = realm.user(id: rawTweet.author_id) else {
                fatalError("Could not find user with id \(rawTweet.author_id)")
            }
            user.insert(tweet)
            
            /// Attach to conversation (create one if necessary).
            var conversation: Conversation
            if let local = realm.conversation(id: rawTweet.conversation_id) {
                conversation = local
            } else {
                conversation = Conversation(id: rawTweet.conversation_id)
                realm.add(conversation)
            }
            conversation.insert(tweet)
            
            /// Check if referenced tweets are in local database.
            for id in tweet.referenced.missingFrom(realm) {
                idsToFetch.insert(id)
            }
        }
    }
    
    try linkRetweets(tweets: tweets, users: users, realm: realm)
    
    /// Check orphaned conversations.
    let orphans = realm.orphanConversations()
    try realm.write {
        for orphan: Conversation in orphans {
            link(orphan: orphan, idsToFetch: &idsToFetch, realm: realm)
        }
    }
    
    return idsToFetch
}

/// Tries to link Tweets to Conversations, and Conversations to Discussions.
/// - Important: MUST take place within a Realm `write` transaction!
fileprivate func link(orphan: Conversation, idsToFetch: inout Set<Tweet.ID>, realm: Realm) -> Void {
    /// Link to upstream's discussion, if possible.
    if
        let upstreamID = orphan.upstream,
        let upstreamConvo = realm.conversation(id: upstreamID),
        let upstream: Discussion = upstreamConvo.discussion.first
    {
        upstream.conversations.append(orphan)
        upstream.update(with: orphan.tweets.map(\.createdAt).max())
        return
    }
    /** Conclusion: upstream is either missing, or itself has no `Discussion`. **/
    
    /// Link the conversation to a local tweet, if needed and possible.
    if
        orphan.root == nil,
        let local = realm.tweet(id: orphan.id)
    {
        orphan.root = local
    }
    
    /// Check if root tweet was still not found.
    guard let root: Tweet = orphan.root else {
        idsToFetch.insert(orphan.id)
        return
    }
    
    /// Remove conversations that are standalone discussions.
    guard let primaryReference: Tweet.ID = root.primaryReference else {
        /// Recognize conversation as its own discussion.
        orphan.upstream = root.id
        realm.add(Discussion(root: orphan))
        return
    }
    
    /// Remove conversations with un-fetched upstream tweets.
    guard let orphanRootReferenced: Tweet = realm.tweet(id: primaryReference) else {
        /// Go fetch the upstream reference.
        idsToFetch.insert(primaryReference)
        return
    }
    
    /// Set upstream conversation.
    let upstreamID: Conversation.ID = orphanRootReferenced.conversation_id
    orphan.upstream = upstreamID
        
    /// Inherit discussion, if possible.
    if
        let upstreamConvo = realm.conversation(id: upstreamID),
        let upstreamDiscussion = upstreamConvo.discussion.first
    {
        upstreamDiscussion.conversations.append(orphan)
        upstreamDiscussion.update(with: orphan.tweets.map(\.createdAt).max())
    } else {
        /// Go fetch the upstream conversation root.
        idsToFetch.insert(upstreamID)
    }
}

/// Mark an inverse relationship.
fileprivate func linkRetweets(tweets: Set<Tweet>, users: Set<User>, realm: Realm) throws -> Void {
    try realm.write {
        for tweet in tweets {
            guard let retweetID = tweet.retweeting else { continue }
            
            /// Safety Checks. A retweet on the timeline should **always** have the original tweet
            /// and the retweeting user included in the response.
            guard
                let original: Tweet = tweets.first(where: {$0.id == retweetID}),
                let retweeter: User = realm.user(id: tweet.authorID)
            else {
                assert(false, "\(retweetID)'s tweet or author not found in return value!")
                return
            }
            
            if original.retweetedBy.contains(retweeter) == false {
                original.retweetedBy.append(retweeter)
            }
        }
    }
}
