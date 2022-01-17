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
    
    /// The root conversation ID, and thereby the root Tweet ID.
    @Persisted(primaryKey: true)
    var id: ID
    typealias ID = Tweet.ID
    
    /// The conversation from which all other conversations in this discussion are "downstream".
    @Persisted
    var root: Conversation?
    
    /// The `createdAt` date of the most recent Tweet in this Discussion.
    @Persisted
    var updatedAt: Date
    public static let updatedAtPropertyName = "updatedAt"
    
    @Persisted
    public private(set) var conversations: List<Conversation>
    public static let conversationsPropertyName = "conversations"
    
    /** "Bell value" for observing changes to Discussion's tweets.
        Problem:
        - We cannot use Realm to observe `tweets` for change notifications, as it is not persisted.
        - `conversations` is not flagged as changing when tweets are added to an existing conversation.
        - How can we use Realm to observe tweets?

        Workaround:
        - Declare an inaccessible, but KVO-compliant, boolean.
        - Toggle the boolean to trigger `observe` when our tweets change.
     */
    @Persisted
    private var tweetsBellValue: Bool = false
    public static let tweetsDidChangeKey = "tweetsBellValue"
    
    override required init() {
        super.init()
    }

    init(root: Conversation) {
        super.init()
        self.id = root.id
        self.root = root
        self.conversations = List<Conversation>()
        self.conversations.append(root)
        
        /// Safe to force unwrap, `root` must have ≥1 `tweets`.
        self.updatedAt = root.tweets.map(\.createdAt).max()!
    }
    
    // MARK: - Ephemeral Variables
    
    /// Memoized Storage.
    var _tweets: [Tweet]?
    var tweets: [Tweet] {
        get {
            if let tweets = _tweets {
                return tweets
            } else {
                let result: [Tweet] = conversations.flatMap(\.tweets)
                _tweets = result
                return result
            }
        }
    }

    /// Memoized read status.
    /// A discussion is 
    /// - `read` if all of its tweets are read.
    /// - `new` if all of its tweets are unread.
    /// - `updated` if some of its tweets are unread.
    var _read: ReadStatus? = nil
    var read: ReadStatus {
        get {
            if let read = _read {
                return read
            } else {
                var result: ReadStatus
                if tweets.allSatisfy(\.read) {
                    result = .read
                } else if tweets.allSatisfy({ $0.read == false }) {
                    result = .new
                } else {
                    result = .updated
                }
                _read = result
                return result
            }
        }
    }
}

extension Discussion {
    /// Mark a discussion as read by marking all tweets as read.
    func markRead(_ token: Realm.TransactionToken) -> Void {
        for tweet in conversations.flatMap(\.tweets) {
            tweet.read = true
        }
        
        /// Force re-calculation.
        _read = nil
        
        /// Notify observers of change.
        tweetsBellValue.toggle()
    }
}

extension Discussion {
    /// Number of tweets, excluding retweets.
    var tweetCount: Int {
        tweets.filter { $0.retweeting == nil }.count
    }
}

extension Discussion {
    /// - Note: must take place within a `Realm` write transaction.
    func patchUpdatedAt(_ token: Realm.TransactionToken) -> Void {
        updatedAt = tweets.map(\.createdAt).max()!
    }
}

extension Discussion {
    func insert(_ conversation: Conversation, _ token: Realm.TransactionToken, realm: Realm) -> Void {
        conversations.append(conversation)
        onUpdateTweets(token)
    }
}

extension Discussion {
    internal func getFollowUp() -> Set<Tweet.ID> {
        conversations
            .flatMap(\.tweets)
            .map(\.danglingReferences)
            .reduce(Set()) { $0.union($1) }
    }
}

extension Discussion {
    /// Call this function whenever `conversations` or their contents change.
    internal func onUpdateTweets(_ token: Realm.TransactionToken) -> Void {
        /// Invalidate memoized values.
        _tweets = nil
        _read = nil
        
        patchUpdatedAt(token)
        
        /// Notify `Realm` observers.
        tweetsBellValue.toggle()
    }
}
