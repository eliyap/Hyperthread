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
    func fullText() -> NSMutableAttributedString {
        /// Replace encoded characters.
        var text = text
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&amp;", with: "<")
        
        /// Replace `t.co` links.
        if let urls = entities?.urls {
            for url in urls {
                guard let target = text.range(of: url.url) else {
                    Swift.debugPrint("Could not find url \(url.url) in \(text)")
                    continue
                }
                text.replaceSubrange(target, with: url.display_url)
            }
        }
        
        /// Apply normal text size and color preferences.
        let string = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.label,
        ])
        
        /// Hyperlink substituted links.
        if let urls = entities?.urls {
            for url in urls {
                /// - Note: Should never fail! We just put this URL in!
                guard let target = text.range(of: url.display_url) else {
                    Swift.debugPrint("Could not find display_url \(url.display_url) in \(text)")
                    continue
                }
                guard
                    let low16 = target.lowerBound.samePosition(in: text.utf16),
                    let upp16 = target.upperBound.samePosition(in: text.utf16)
                else {
                    Swift.debugPrint("Could not cast offsets")
                    continue
                }
                let lowInt = text.utf16.distance(from: text.utf16.startIndex, to: low16)
                let uppInt = text.utf16.distance(from: text.utf16.startIndex, to: upp16)
                string.addAttribute(.link, value: url.url, range: NSMakeRange(lowInt, uppInt-lowInt))
            }
        }
        
        return string
    }
}
