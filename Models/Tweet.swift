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

/**
 Represents the set of references held by a Tweet.
 */
internal struct ReferenceSet: OptionSet {
    var rawValue: Int
    
    typealias RawValue = Int
    
    static let reply = Self(rawValue: 1 << 0)
    static let quote = Self(rawValue: 1 << 1)
    static let retweet = Self(rawValue: 1 << 2)
    
    static let empty: Self = []
    static let all: Self = [.reply, .quote, .retweet]
}

final class Tweet: Object, Identifiable, AuthorIdentifiable, TweetIdentifiable {
    
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
    public static let retweetingPropertyName = "retweeting"
    
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
    
    @Persisted
    private var _relevance: Relevance.RawValue
    public static let relevancePropertyName = "_relevance"
    public var relevance: Relevance! {
        get { .init(rawValue: _relevance) }
        set { _relevance = newValue.rawValue }
    }
    
    /** The set of referenced tweets which have yet to be fetched.
        If empty, we should be able to find the Tweet in our Realm by the stored reference ID.
     */
    @Persisted
    private var _dangling: ReferenceSet.RawValue
    public static let danglingPropertyName = "_dangling"
    public var dangling: ReferenceSet! {
        get { .init(rawValue: _dangling) }
        set { _dangling = newValue.rawValue}
    }
    
    init(raw: RawHydratedTweet, rawMedia: [RawIncludeMedia], relevance: Relevance) {
        super.init()
        self.id = raw.id
        self.createdAt = raw.created_at
        self.text = raw.text
        self.conversation_id = raw.conversation_id
        self.metrics = PublicMetrics(raw: raw.public_metrics)
        self.authorID = raw.author_id
        self.read = false
        
        var referenceSet: ReferenceSet = .empty
        if let references = raw.referenced_tweets {
            for reference in references {
                switch reference.type {
                case .replied_to:
                    replying_to = reference.id
                    referenceSet.formUnion(.reply)
                case .quoted:
                    quoting = reference.id
                    referenceSet.formUnion(.quote)
                case .retweeted:
                    retweeting = reference.id
                    referenceSet.formUnion(.retweet)
                }
            }
        }
        dangling = referenceSet
        
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
        
        self.relevance = relevance
    }
    
    convenience init(raw: RawHydratedTweet, rawMedia: [RawIncludeMedia], following: [User.ID]) {
        self.init(raw: raw, rawMedia: rawMedia, relevance: Relevance(tweet: raw, following: following))
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
    
    public func getFollowUp(realm: Realm) -> Set<Tweet.ID> {
        Set(referenced.filter { realm.tweet(id: $0) == nil })
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
    
    var danglingReferences: Set<Tweet.ID> {
        var result: Set<Tweet.ID> = .init()
        if dangling.contains(.reply) {
            guard let replyID = replying_to else {
                ModelLog.error("Tweet \(id) has dangling reply but no replying_to ID")
                assert(false)
                return result
            }
            result.insert(replyID)
        }
        if dangling.contains(.quote) {
            guard let quoteID = quoting else {
                ModelLog.error("Tweet \(id) has dangling quote but no quoting ID")
                assert(false)
                return result
            }
            result.insert(quoteID)
        }
        if dangling.contains(.retweet) {
            guard let retweetID = retweeting else {
                ModelLog.error("Tweet \(id) has dangling retweet but no retweeting ID")
                assert(false)
                return result
            }
            result.insert(retweetID)
        }
        return result
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
    static let chronologicalSort = { (lhs: Tweet, rhs: Tweet) -> Bool in
        /// Tie break by ID.
        /// I have observed tied timestamps. (see https://twitter.com/ChristianSelig/status/1469028219441623049)
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        } else {
            return lhs.id < rhs.id
        }
    }
}

extension Realm {
    /// Attach `tweet` to a conversation, creating one if necessary.
    func linkConversation(_: TransactionToken, tweet: Tweet) -> Void {
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
            discussion.notifyTweetsDidChange()
        }
    }
}

extension Tweet: ReplyIdentifiable {
    var replyID: String? { replying_to }
}

extension Realm {
    /// Find tweets with possibly dangling
    internal func updateDangling() throws -> Void {
        let tweets = objects(Tweet.self)
            .filter(.init(format: "\(Tweet.danglingPropertyName) > 0"))
        
        /// Do a just-in-time check for tweets which are no longer dangling.
        try writeWithToken { token in
            for tweet in tweets {
                updateReferenceSet(token, tweet: tweet)
            }
        }
    }
}

extension Realm {
    /** Update the reference set based on what is present in the database*/
    fileprivate func updateReferenceSet(_ token: TransactionToken, tweet: Tweet) -> Void {
        if tweet.dangling.contains(.reply) {
            guard let replyID = tweet.replying_to else {
                ModelLog.error("Illegal State! Reply ID missing!")
                assert(false)
                return
            }
            if self.tweet(id: replyID) != nil {
                tweet.dangling.remove(.reply)
            }
        }

        if tweet.dangling.contains(.quote) {
            guard let quoteID = tweet.quoting else {
                ModelLog.error("Illegal State! Quote ID missing!")
                assert(false)
                return
            }
            if self.tweet(id: quoteID) != nil {
                tweet.dangling.remove(.quote)
            }
        }

        if tweet.dangling.contains(.retweet) {
            guard let retweetID = tweet.retweeting else {
                ModelLog.error("Illegal State! Retweet ID missing!")
                assert(false)
                return
            }
            if self.tweet(id: retweetID) != nil {
                tweet.dangling.remove(.retweet)
            }
        }
    }
}
