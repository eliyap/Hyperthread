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
    var like_count: Int
    
    @Persisted 
    var retweet_count: Int

    @Persisted
    var reply_count: Int

    @Persisted
    var quote_count: Int
    
    override required init() {
    }
    
    init(raw: RawPublicMetrics) {
        like_count = raw.like_count
        retweet_count = raw.retweet_count
        reply_count = raw.reply_count
        quote_count = raw.quote_count    
    }
}

final class URLEntity: EmbeddedObject {
    @Persisted
    var start: Int

    @Persisted
    var end: Int

    @Persisted
    var url: String

    @Persisted
    var expanded_url: String

    @Persisted
    var display_url: String

    override required init() {}

    init(raw: RawURL) {
        start = raw.start
        end = raw.end
        url = raw.url
        expanded_url = raw.expanded_url
        display_url = raw.display_url
    }
}

final class Annotation: EmbeddedObject {
    
    @Persisted
    var start: Int

    @Persisted
    var end: Int

    @Persisted
    var text: String

    @Persisted
    var probability: Double

    @Persisted
    var type: String

    override required init() {}

    init(raw: RawAnnotation) {
        start = raw.start
        end = raw.end
        text = raw.normalized_text
        probability = raw.probability
        type = raw.type
    }
}

final class Entities: EmbeddedObject {
    @Persisted
    var annotations: List<Annotation>
    
    @Persisted
    var hashtags: List<Tag>

    @Persisted
    var mentions: List<Mention>

    @Persisted
    var urls: List<URLEntity>

    override required init() {}
    
    init(raw: RawEntities) {
        super.init()
        raw.annotations?.map(Annotation.init).forEach(annotations.append)
        raw.hashtags?.map(Tag.init).forEach(hashtags.append)
        raw.mentions?.map(Mention.init).forEach(mentions.append)
        raw.urls?.map(URLEntity.init).forEach(urls.append)
    }
    
    /// Void differentiates this private init from the public one.
    private init(_: Void) {
        super.init()
        annotations = List<Annotation>()
        hashtags = List<Tag>()
        mentions = List<Mention>()
        urls = List<URLEntity>()
    }

    /// Represents a case with no entities.
    public static let empty = Entities()
}

/// Represents a Hashtag or Cashtag.
final class Tag: EmbeddedObject {
    @Persisted
    public var start: Int
    
    @Persisted
    public var end: Int
    
    @Persisted
    public var tag: String
    
    override required init() {
    }
    
    init(raw: RawTag) {
        super.init()
        start = raw.start
        end = raw.end
        tag = raw.tag
    }
}

final class Mention: EmbeddedObject {
    @Persisted
    public var start: Int
    
    @Persisted
    public var end: Int
    
    @Persisted
    public var id: User.ID

    @Persisted
    public var handle: String
    
    override required init() {
    }
    
    init(raw: RawMention) {
        start = raw.start
        end = raw.end
        id = raw.id
        handle = raw.username
    }
}

final class Tweet: Object, Identifiable {
    
    /// Twitter API `id`.
    @Persisted(primaryKey: true) 
    var id: ID
    typealias ID = String
    
    @Persisted
    var createdAt: Date
    
    /// Tweet's body text.
    @Persisted 
    var text: String
    
    /// - Note: Realm requires embedded objects to be optional.
    @Persisted
    var metrics: PublicMetrics!
    
    /// - Note: `LinkingObjects` failed me, so use an ID instead.
    /// Fortunately, we can assume that a Tweet will never change users.
    @Persisted
    var authorID: User.ID
    
    /// - Note: Tweet must belong to a unique ``Conversation``.
    @Persisted(originProperty: Conversation.tweetsPropertyName)
    var conversation: LinkingObjects<Conversation>
    public static let conversationPropertyName = "conversation"
    
    /// The ID whose `Conversation` this Tweet belongs to.
    /// Note this is also the ID of the Conversation's root tweet.
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
        self.createdAt = raw.created_at
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
    
    /// Create the "canonical" Tweet text from Twitter's encoded / shortened version.
    private func expandedText(raw: RawHydratedTweet) -> String {
        var entities: Entities
        if let rawEntities = raw.entities {
            entities = Entities(raw: rawEntities)
        } else {
            entities = .empty
        }
        
        entities.urls
            .sorted(by: {$0.start > $1.start})
            .forEach { url in
                print(url.url)
            }
        
        return ""
    }
}

extension Tweet {
    /// The tweet we consider this tweet to be primarily "pointing to".
    /// Resolves in (personally preferred) order of precedence.
    var primaryReference: ID? {
        replying_to ?? quoting ?? retweeting
    }
    
    var primaryReferenceType: RawReferenceType? {
        if replying_to != nil { return .replied_to }
        if quoting != nil { return .quoted }
        if retweeting != nil { return .retweeted }
        return .none
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
