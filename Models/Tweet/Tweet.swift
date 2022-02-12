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

final class Tweet: Object, Identifiable, AuthorIdentifiable, TweetIdentifiable {
    
    /// Twitter API `id`.
    @Persisted(primaryKey: true) 
    var id: ID
    typealias ID = String
    
    /// Tweet's creation time.
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
    public static let authorIDPropertyName = "authorID"
    
    /// - Note: Tweet must belong to a unique ``Conversation``.
    @Persisted(originProperty: Conversation.tweetsPropertyName)
    var conversation: LinkingObjects<Conversation>
    public static let conversationPropertyName = "conversation"
    
    /// The ID whose `Conversation` this Tweet belongs to.
    /// Note this is also the ID of the Conversation's root tweet.
    @Persisted
    var conversation_id: ID
    
    /// If this tweet is a reply, this property represents the ID of the tweet this is a reply to.
    @Persisted
    var replying_to: ID?
    public static let replyingPropertyName = "replying_to"
    
    /// If this tweet is a reply, this represents the ID of the author this tweet is a reply to.
    @Persisted
    var inReplyToUserID: User.ID?
    
    /// If this tweet is a retweet, this represents the ID of retweeted tweet.
    @Persisted
    var retweeting: ID?
    public static let retweetingPropertyName = "retweeting"
    
    /// If this tweet is a quote, this represents the ID of quoted tweet.
    @Persisted
    var quoting: ID?
    public static let quotingPropertyName = "quoting"
    
    /// - Note: Realm requires embedded objects to be optional.
    @Persisted
    var entities: Entities?
    
    /// Whether the user has read this tweet.
    /// App internal, not from Twitter.
    @Persisted
    var read: Bool
    
    /// Attached images, videos, GIFs, etc.
    @Persisted
    var media: List<Media>
    public static let mediaPropertyName = "media"
    
    /** App-internal (non-Twitter) measure of a tweet's "relevance".
        Less relevant Tweets / Discussions are excluded from the timeline.
     */
    @Persisted
    private var _relevance: Relevance.RawValue
    public static let relevancePropertyName = "_relevance"
    public var relevance: Relevance! {
        get { .init(rawValue: _relevance) }
        set { _relevance = newValue.rawValue }
    }
    
    /** The set of referenced tweets which have yet to be fetched.
        If empty, we should be able to find all referenced Tweets in our Realm by looking up the stored reference ID.
     */
    @Persisted
    private var _dangling: ReferenceSet.RawValue
    public static let danglingPropertyName = "_dangling"
    public var dangling: ReferenceSet! {
        get { .init(rawValue: _dangling) }
        set { _dangling = newValue.rawValue}
    }
    
    init(
        raw: RawHydratedTweet,
        rawMedia: [RawIncludeMedia],
        relevance: Relevance,
        read: Bool
    ) {
        super.init()
        self.id = raw.id
        self.createdAt = raw.created_at
        self.text = raw.text
        self.conversation_id = raw.conversation_id
        self.metrics = PublicMetrics(raw: raw.public_metrics)
        self.authorID = raw.author_id
        self.inReplyToUserID = raw.in_reply_to_user_id
        self.read = read
        
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
                    ModelLog.error("Failed to find match for \(key)")
                    assert(false)
                    continue
                }
                media.append(Media(raw: match))
            }
        }
        
        self.relevance = relevance
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
    lazy var attributedString: NSAttributedString = fullText(context: nil)
}

extension Tweet {
    public static let notAvailableMessage = """
        This tweet is unavailable.
        The author may have hidden or deleted it.
        """
    public static func notAvailableAttributedString(id: Tweet.ID) -> NSAttributedString {
        let str = NSMutableAttributedString(string: Tweet.notAvailableMessage, attributes: Tweet.textAttributes)
        
        /// Direct user to status URL. I don't fully trust my system, so this is a slapdash fallback option.
        /// The `s` is a placeholder, it doesn't matter as Twitter will redirect.
        /// `0, 10` aims to cover "This tweet".
        str.addAttribute(.link, value: "https://twitter.com/s/status/\(id)", range: NSMakeRange(0, 10))
        return str
    }
}

