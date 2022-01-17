//
//  LinkConversations.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 17/1/22.
//

import Foundation
import RealmSwift

/// Links detached `Conversation` to `Discussion`s where possible,
/// and if not possible finds what `Tweet` needs to be fetched to make the connection.
///
/// - Returns: list of `Tweet.ID`s to be fetched.
internal func linkConversations() throws -> Set<Tweet.ID> {
    var idsToFetch = Set<Tweet.ID>()
    
    let realm = try! Realm()
    
    /// Check unlinked conversations.
    let unlinked = realm.objects(Conversation.self)
        .filter(NSPredicate(format: "\(Conversation.discussionPropertyName).@count == 0"))
    try realm.writeWithToken { token in
        for conversation in unlinked {
            let missing: Tweet.ID? = link(token, conversation: conversation, realm: realm)
            if let missing = missing {
                idsToFetch.insert(missing)
            }
        }
    }
    
    return idsToFetch
}

/// Tries to link `Conversation`s to `Discussion`s by searching the `Realm`
/// for a referenced (or "upstream") Tweet, Conversation, and its Discussion.
///
/// May fail to link a `Conversation` if its "upstream" is missing from the `Realm`.
/// - Returns: the missing "upstream" tweet to be fetched, if any.
fileprivate func link(
    _ token: Realm.TransactionToken,
    conversation: Conversation,
    realm: Realm
) -> Tweet.ID? {
    /// If the upstream `Conversation` is known, and it has a `Discussion`,
    /// simply link this `Conversation` to that `Discussion`.
    if
        let upstreamID = conversation.upstream,
        let upstreamConvo = realm.conversation(id: upstreamID),
        let upstream: Discussion = upstreamConvo.discussion.first
    {
        upstream.insert(conversation, token, realm: realm)
        return nil
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
        return conversation.id
    }
    
    /// Remove conversations that are standalone discussions.
    guard let rootPRID: Tweet.ID = root.primaryReference else {
        /// Since the `root` has no references, its conversation is the `Discussion.root`.
        /// Recognize the `Conversation` as a `Discussion` root by marking it as its own upstream.
        conversation.upstream = root.id
        realm.add(Discussion(root: conversation))
        return nil
    }
    
    /// Remove conversations with un-fetched upstream tweets.
    guard let rootPrimaryReference: Tweet = realm.tweet(id: rootPRID) else {
        /// Go fetch the upstream reference.
        return rootPRID
    }
    
    /// Set upstream conversation.
    let upstreamID: Conversation.ID = rootPrimaryReference.conversation_id
    conversation.upstream = upstreamID
        
    /// Check if the upstream `Conversation` is fetched, and has a `Discussion`.
    guard
        let upstreamConvo = realm.conversation(id: upstreamID),
        let upstream: Discussion = upstreamConvo.discussion.first
    else {
        /// Otherwise, fetch the upstream Conversation's root Tweet.
        return upstreamID
    }
    
    upstream.insert(conversation, token, realm: realm)
    return nil
}
