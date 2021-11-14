//
//  BigFetch.swift
//  BranchRealm
//
//  Created by Secret Asian Man Dev on 31/10/21.
//

import Foundation
import RealmSwift
import Twig


func furtherFetch(rawTweets: [RawHydratedTweet], rawUsers: [RawIncludeUser]) throws -> Set<Tweet.ID> {
    let realm = try! Realm()
    
    /// IDs for further fetching.
    var idsToFetch = Set<Tweet.ID>()
    
    /// Insert all users.
    try realm.write {
        for rawUser in rawUsers {
            realm.add(User(raw: rawUser), update: .modified)
        }
    }
    
    /// Insert all tweets.
    try realm.write {
        for rawTweet in rawTweets {
            let tweet: Tweet = Tweet(raw: rawTweet)
            realm.add(tweet, update: .modified)
            
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
    
    /// Check orphaned conversations.
    let orphans = realm.orphanConversations()
    try realm.write {
        for orphan: Conversation in orphans {
            /// Link to upstream's discussion, if possible.
            if
                let upstreamID = orphan.upstream,
                let upstreamConvo = realm.conversation(id: upstreamID),
                let upstream: Discussion = upstreamConvo.discussion.first
            {
                upstream.conversations.append(orphan)
                upstream.update(with: orphan.tweets.map(\.createdAt).max())
                continue
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
                continue
            }
            
            /// Remove conversations that are standalone discussions.
            guard let primaryReference: Tweet.ID = root.primaryReference else {
                /// Recognize conversation as its own discussion.
                orphan.upstream = root.id
                realm.add(Discussion(root: orphan))
                continue
            }
            
            /// Remove conversations with un-fetched upstream tweets.
            guard let orphanRootReferenced: Tweet = realm.tweet(id: primaryReference) else {
                /// Go fetch the upstream reference.
                idsToFetch.insert(primaryReference)
                continue
            }
            
            /// Set upstream conversation.
            let upstreamID = orphanRootReferenced.conversation_id
            orphan.upstream = upstreamID
                
            /// Inherit discussion, if possible.
            if
                let upstreamConvo = realm.conversation(id: upstreamID),
                let upstreamDiscussion = upstreamConvo.discussion.first
            {
                upstreamDiscussion.conversations.append(orphan)
            } else {
                /// Go fetch the upstream conversation root.
                idsToFetch.insert(upstreamID)
            }
        }
    }
    
    return idsToFetch
}
