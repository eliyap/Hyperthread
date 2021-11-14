//
//  Query.swift
//  BranchRealm
//
//  Created by Secret Asian Man Dev on 31/10/21.
//

import RealmSwift

extension Realm {
    func tweet(id: Tweet.ID) -> Tweet? {
        object(ofType: Tweet.self, forPrimaryKey: id)
    }
    
    func user(id: User.ID) -> User? {
        object(ofType: User.self, forPrimaryKey: id)
    }
    
    func conversation(id: Conversation.ID) -> Conversation? {
        object(ofType: Conversation.self, forPrimaryKey: id)
    }
    
    func discussion(id: Discussion.ID) -> Discussion? {
        object(ofType: Discussion.self, forPrimaryKey: id)
    }
}

extension Realm {
    func orphanConversations() -> Results<Conversation> {
        objects(Conversation.self)
            .filter("\(Conversation.discussionPropertyName).@count == 0")
    }
}

extension Realm {
    func orphanTweets() -> Results<Tweet> {
        objects(Tweet.self)
            .filter("\(Tweet.conversationPropertyName).@count == 0")
    }
}
