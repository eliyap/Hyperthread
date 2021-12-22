//
//  TweetLinker.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 21/12/21.
//

import Foundation
import RealmSwift

extension Realm {
    /**
     Look for `Conversation`s which need to be added to a `Discussion`.
     */
    internal func findOrphans() -> Results<Conversation> {
        objects(Conversation.self)
            .filter(NSCompoundPredicate(andPredicateWithSubpredicates: [
                .init(format: "\(Conversation.discussionPropertyName).@count == 0"),
                .init(format: "\(Conversation.maxRelevancePropertyName) >= \(Relevance.threshold)")
            ]))
    }
}

internal func _linkOrphans() throws -> Set<Tweet.ID> {
    var idsToFetch = Set<Tweet.ID>()
    
    let realm = try! Realm()
    
    /// Check orphaned conversations.
    let orphans = realm.findOrphans()
    try realm.write {
        for orphan: Conversation in orphans {
            link(orphan: orphan, idsToFetch: &idsToFetch, realm: realm)
        }
    }
    
    return idsToFetch
}
