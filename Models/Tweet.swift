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
    
    override required init() {}
    
    init(raw: RawPublicMetrics) {
        like_count = raw.like_count
        retweet_count = raw.retweet_count
        reply_count = raw.reply_count
        quote_count = raw.quote_count    
    }

    internal init(
        like_count: Int,
        retweet_count: Int,
        reply_count: Int,
        quote_count: Int
    ) {
        self.like_count = like_count
        self.retweet_count = retweet_count
        self.reply_count = reply_count
        self.quote_count = quote_count
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
    
    /// Whether the user has read this tweet.
    @Persisted
    var read: Bool
    
    @Persisted
    var media: List<Media>
    
    init(raw: RawHydratedTweet, rawMedia: [RawIncludeMedia]) {
        super.init()
        self.id = raw.id
        self.createdAt = raw.created_at
        self.text = raw.text
        self.conversation_id = raw.conversation_id
        self.metrics = PublicMetrics(raw: raw.public_metrics)
        self.authorID = raw.author_id
        self.read = false
        
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
        
        media = List<Media>()
        if let keys = raw.attachments?.media_keys {
            /// - Note: order of images is significant, so we MUST NOT use the `Set` trick for de-duping!
            for key in keys.removingDuplicates() {
                guard let match = rawMedia.first(where: {$0.media_key == key}) else {
                    Swift.debugPrint("Failed to find match for \(key)")
                    continue
                }
                media.append(Media(raw: match))
            }
        }
    }
    
    override required init() {
        super.init()
    }
    
    // MARK: - Ephemeral Variables
    
    /**
     Memoize the canonical display `NSAttributedString` for teaser & header displays (where there is no `context`).
     This should never change because it is calculated using
     - `entities`
     - `text`
     
     These should never change, so we can safely memoize.
     */
    /// Memoized display string.
    lazy var attributedString: NSAttributedString = {
        fullText(context: nil)
    }()
    
    /// Test method for creating a fake tweet.
    private init(_: Void) {
        super.init()
        
        self.id = UUID().uuidString
        self.createdAt = Date()
        self.text = "This is a fake tweet."
        self.conversation_id = id
        self.metrics = PublicMetrics(like_count: 0, retweet_count: 0, reply_count: 0, quote_count: 0)
        self.authorID = OwnUserID
        self.read = false
    }
    
    public static func generateFake() -> Tweet {
        .init(Void())
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
    var isRetweet: Bool { retweeting != nil }
    var isQuote: Bool { quoting != nil }
    var isReply: Bool { replying_to != nil }
}

extension Tweet {
    static let chronologicalSort: (Tweet, Tweet) -> Bool = { (lhs: Tweet, rhs: Tweet) in
        /// Tie break by ID.
        /// I have observed tied timestamps. (see https://twitter.com/ChristianSelig/status/1469028219441623049)
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        } else {
            return lhs.id < rhs.id
        }
    }
}
