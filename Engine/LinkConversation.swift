//
//  LinkConversation.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 17/1/22.
//

import Foundation
import RealmSwift

extension Realm {
    /// Attach `tweet` to a conversation, creating one if necessary.
    func linkConversation(_ token: TransactionToken, tweet: Tweet) -> Void {
        /// Attach to conversation (create one if necessary).
        var conversation: Conversation
        if let local = self.conversation(id: tweet.conversation_id) {
            conversation = local
        } else {
            conversation = Conversation(id: tweet.conversation_id)
            self.add(conversation)
        }
        
        /// Add tweet to conversation.
        conversation.insert(tweet)
        
        if let discussion = conversation.discussion.first {
            discussion.notifyTweetsDidChange(token)
        }
    }
}
