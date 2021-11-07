//
//  Tweet.swift
//  BranchRealm
//
//  Created by Secret Asian Man Dev on 29/10/21.
//

import Foundation
import RealmSwift
import Realm
import Twig

final class PublicMetrics: EmbeddedObject {
    
    @Persisted 
    var favorite_count: Int?
    
    @Persisted 
    var retweet_count: Int

    @Persisted
    var reply_count: Int

    @Persisted
    var quote_count: Int
    
    override required init() {
    }
    
    init(raw: RawPublicMetrics) {
        favorite_count = raw.like_count
        retweet_count = raw.retweet_count
        reply_count = raw.reply_count
        quote_count = raw.quote_count    
    }
}

final class Tweet: Object, Identifiable {
    
    /// Twitter API `id`.
    @Persisted(primaryKey: true) 
    var id: ID
    typealias ID = String
    
    /// Tweet's body text.
    @Persisted 
    var text: String
    
    @Persisted
    var metrics: PublicMetrics?
    
    /// - Note: `LinkingObjects` failed me, so use an ID instead.
    /// Fortunately, we can assume that a Tweet will never change users.
    @Persisted
    var authorID: User.ID
    
    /// - Note: Tweet must belong to a unique ``Conversation``.
    @Persisted(originProperty: Conversation.tweetsPropertyName)
    var conversation: LinkingObjects<Conversation>
    
    @Persisted
    var conversation_id: ID
    
    @Persisted
    var replying_to: ID?
    
    @Persisted
    var retweeting: ID?
    
    @Persisted
    var quoting: ID?
    
    init(raw: RawHydratedTweet) {
        super.init()
        self.id = raw.id
        self.text = raw.text
        self.conversation_id = raw.conversation_id
        self.metrics = PublicMetrics(raw: raw.public_metrics)
        self.authorID = raw.author_id
        
        if let references = raw.referenced_tweets {
            for reference in references {
                switch reference.type {
                case .replied_to:
                    replying_to = reference.id
                case .quoted:
                    quoting = reference.id
                case .retweeted:
                    retweeting = reference.id
                }
            }
        }
    }
    
    override required init() {
        super.init()
    }
}

extension Tweet {
    /// The tweet we consider this tweet to be primarily "pointing to".
    /// Resolves in (personally preferred) order of precedence.
    var primaryReference: ID? {
        replying_to ?? quoting ?? retweeting
    }
}

// MARK: - Convenience Methods.
extension Tweet {
    var referenced: [ID] {
        [
            replying_to,
            retweeting,
            quoting
        ].compactMap { $0 }
    }
}

extension Tweet.ID {
    func missingFrom(_ realm: Realm) -> Bool {
        realm.tweet(id: self) == nil
    }
}

extension Array where Element == Tweet.ID {
    func missingFrom(_ realm: Realm) -> Self {
        filter { $0.missingFrom(realm) }
    }
}
