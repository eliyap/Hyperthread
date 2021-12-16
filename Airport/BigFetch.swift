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
 Links Tweets to Conversations, and Conversations to Discussions.
 - Returns: IDs of Tweets which need to be fetched.
 */
func furtherFetch(
    rawTweets: [RawHydratedTweet],
    rawUsers: [RawIncludeUser],
    rawMedia: [RawIncludeMedia]
) throws -> Set<Tweet.ID> {
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
    
    /// First, pick out tweets with missing media keys.
    let mediaKeys = rawMedia.map(\.media_key)
    let rawTweets = rawTweets.filter { rawTweet in
        /// Pass on anything without media keys.
        guard let keys = rawTweet.attachments?.media_keys, keys.isNotEmpty else { return true }
        if keys.allSatisfy({ mediaKeys.contains($0) }) {
            return true
        } else {
            /// Request these tweets again.
            idsToFetch.insert(rawTweet.id)
            return false
        }
    }
    
    /// Insert Tweets into local database.
    try realm.write {
        for rawTweet in rawTweets {
            let tweet: Tweet = Tweet(raw: rawTweet, rawMedia: rawMedia)
            realm.add(tweet, update: .modified)
            tweets.insert(tweet)
            
            /// Safety check: we count on the user never being missing!
            if realm.user(id: rawTweet.author_id) == nil {
                fatalError("Could not find user with id \(rawTweet.author_id)")
            }
            
            /// Attach to conversation (create one if necessary).
            var conversation: Conversation
            if let local = realm.conversation(id: rawTweet.conversation_id) {
                conversation = local
            } else {
                conversation = Conversation(id: rawTweet.conversation_id)
                realm.add(conversation)
            }
            conversation.insert(tweet)
            if let discussion = conversation.discussion.first {
                discussion.notifyTweetsDidChange()
            }
            
            /// Check if referenced tweets are in local database.
            for id in tweet.referenced.missingFrom(realm) {
                idsToFetch.insert(id)
            }
        }
    }
    
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
        
        /// Bump update time.
        upstream.update(with: orphan.tweets.map(\.createdAt).max())
        
        /// Mark as updated (new discussions should stay new).
        if upstream.read == .read {
            upstream.read = .updated
        }
        
        upstream.notifyTweetsDidChange()
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
        
        /// Note a new discussion above the fold.
        UserDefaults.groupSuite.incrementScrollPositionRow()
        
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
        upstreamDiscussion.notifyTweetsDidChange()
    } else {
        /// Go fetch the upstream conversation root.
        idsToFetch.insert(upstreamID)
    }
}
