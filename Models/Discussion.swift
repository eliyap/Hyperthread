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
