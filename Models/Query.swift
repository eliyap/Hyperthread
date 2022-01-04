//
//  Query.swift
//  BranchRealm
//
//  Created by Secret Asian Man Dev on 31/10/21.
//

import RealmSwift
import Twig

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
    func followingUsers() -> Results<User> {
        objects(User.self)
            .filter("\(User.followingPropertyName) == YES")
    }
}

extension Realm {
    
    func conversationsWithFollowUp() -> Results<Conversation> {
        objects(Conversation.self)
            .filter(NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "\(Conversation.discussionPropertyName).@count == 0")
            ]))
    }
    
    func discussionsWithFollowUp() -> Results<Discussion> {
        objects(Discussion.self)
            .filter(NSCompoundPredicate(andPredicateWithSubpredicates: [
                /// Check if any `Tweet` is above the relevance threshold.
                Discussion.minRelevancePredicate,
                
                /// Check if any `Tweet` has dangling references.
                Discussion.danglingReferencePredicate,
            ]))
    }
}
    
extension Discussion {
    /// Check if any `Tweet` is above the relevance threshold.
    static let minRelevancePredicate = NSPredicate(format: """
        SUBQUERY(\(Discussion.conversationsPropertyName), $c,
            SUBQUERY(\(Conversation.tweetsPropertyName), $t,
                $t.\(Tweet.relevancePropertyName) >= \(Relevance.threshold)
            ).@count > 0
        ).@count > 0
        """)
    
    /// Check if any `Tweet` has dangling references.
    static let danglingReferencePredicate = NSPredicate(format: """
        SUBQUERY(\(Discussion.conversationsPropertyName), $c,
            SUBQUERY(\(Conversation.tweetsPropertyName), $t,
                $t.\(Tweet.danglingPropertyName) > \(ReferenceSet.empty.rawValue)
            ).@count > 0
        ).@count > 0
        """)
}

/** From a `RawData` blob, find the users which were mentioned but not included.
 */
func findMissingMentions(
    tweets: [RawHydratedTweet],
    includes: [RawHydratedTweet] = [],
    users: [RawUser]
) -> [User.ID] {
    let mentionedIDs: [User.ID] = (tweets + includes)
        .compactMap(\.entities?.mentions)
        .flatMap { $0 }
        .map(\.id)
    
    let fetchedIDs = users.map(\.id)
    
    return mentionedIDs.filter { fetchedIDs.contains($0) == false }
}
