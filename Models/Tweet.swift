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
        raw.annotations?.map(Annotation.init(raw: )).forEach(annotations.append)
        raw.hashtags?.map(Tag.init(raw: )).forEach(hashtags.append)
        raw.mentions?.map(Mention.init(raw: )).forEach(mentions.append)
        raw.urls?.map(URLEntity.init(raw: )).forEach(urls.append)
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
    
    /// - Note: Realm requires embedded objects to be optional.
    @Persisted
    var entities: Entities?
    
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
        
        if let rawEntities = raw.entities {
            entities = Entities(raw: rawEntities)
        } else {
            entities = nil
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

extension Tweet {
    func fullText() -> NSAttributedString {
        var text = text
        
        if let urls = entities?.urls {
            urls.forEach { url in
                if let rng = text.range(url.start..<url.end) {
                    text.replaceSubrange(rng, with: url.display_url)
                    Swift.debugPrint(url.display_url)
                }
            }
        }
        
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        text = text.replacingOccurrences(of: "&lt;", with: "<")
        
        return NSAttributedString(string: text)
    }
}

fileprivate extension String {
    
    func range(_ range: Range<Int>) -> Range<String.Index>? {
        guard let utf16Range = utf16.range(range) else {
            Swift.debugPrint(utf8.count)
            return nil
        }
        guard let lower = utf16Range.lowerBound.samePosition(in: self) else {
            Swift.debugPrint("Could not convert lower bound")
            Swift.debugPrint("upper \(range.upperBound), lower \(range.lowerBound), count \(count), utf16 \(utf16.count)")
            return nil
        }
        guard let upper = utf16Range.upperBound.samePosition(in: self) else {
            Swift.debugPrint("Could not convert upper bound")
            return nil
        }
        return lower..<upper
        
//        guard range.lowerBound <= count, range.upperBound <= count else {
//            Swift.debugPrint("Could not form range for '\(self)'. upper \(range.upperBound), lower \(range.lowerBound), count \(count)")
//            Swift.debugPrint(utf16.count)
//            return nil
//        }
//        let start = index(startIndex, offsetBy: range.lowerBound)
//        let end = index(startIndex, offsetBy: range.upperBound)
//        return start..<end
    }
}

fileprivate extension String.UTF16View {
    func range(_ range: Range<Int>) -> Range<String.Index>? {
        guard range.lowerBound <= count, range.upperBound <= count else {
            Swift.debugPrint("Could not form range for '\(self)'. upper \(range.upperBound), lower \(range.lowerBound), count \(count)")
            return nil
        }
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(startIndex, offsetBy: range.upperBound)
        return start..<end
    }
}

fileprivate extension String.UTF8View {
    func range(_ range: Range<Int>) -> Range<String.Index>? {
        guard range.lowerBound <= count, range.upperBound <= count else {
            Swift.debugPrint("Could not form range for '\(self)'. upper \(range.upperBound), lower \(range.lowerBound), count \(count)")
            return nil
        }
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(startIndex, offsetBy: range.upperBound)
        return start..<end
    }
}
