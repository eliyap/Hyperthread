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
    
    @Persisted
    var root: Conversation?
    
    /// The `createdAt` date of the most recent Tweet in this Discussion.
    @Persisted
    var updatedAt: Date
    public static let updatedAtPropertyName = "updatedAt"
    
    @Persisted
    var conversations: List<Conversation> {
        didSet {
            /// Wipe memoized storage.
            _tweets = nil
        }
    }
    public static let conversationsPropertyName = "conversations"
    
    @Persisted
    var readStatus: ReadStatus.RawValue
    public static let readStatusPropertyName = "readStatus"
    
    override required init() {
        super.init()
    }

    init(root: Conversation) {
        super.init()
        self.id = root.id
        self.root = root
        self.conversations = List<Conversation>()
        self.conversations.append(root)
        self.readStatus = ReadStatus.new.rawValue
        
        /// Safe to force unwrap, `root` must have ≥1 `tweets`.
        self.updatedAt = root.tweets.map(\.createdAt).max()!
    }
    
    // MARK: - Ephemeral Variables
    
    /// Memoized Storage.
    var _tweets: [Tweet]?
    var tweets: [Tweet] {
        get {
            if let tweets = _tweets { return tweets }
            else {
                let result: [Tweet] = conversations.flatMap(\.tweets)
                _tweets = result
                return result
            }
        }
    }
}

extension Discussion {
    /// Should never have an invalid value.
    var read: ReadStatus! {
        get { .init(rawValue: readStatus) }
        set { readStatus = newValue.rawValue }
    }
}

extension Discussion {
    /// Number of tweets, excluding retweets.
    var tweetCount: Int {
        tweets.filter { $0.retweeting == nil }.count
    }
}

extension Discussion {
    func relevantTweets(followingUserIDs: [String]?) -> [Tweet] {
        let tweets = self.tweets
        guard let followingUserIDs = followingUserIDs else { 
            Swift.debugPrint("No followingUserIDs, returning list unaltered.")
            return tweets 
        }
        var result = Set<Tweet>()

        /// Include tweets from following users.
        var followingTweets = [Tweet]()
        for tweet in tweets {
            if followingUserIDs.contains(tweet.authorID) {
                followingTweets.append(tweet)
            }
        }
        result.formUnion(followingTweets)
        
        /// Include tweets that they referenced.
        var refIDs = Set<Tweet.ID>()
        for tweet in followingTweets {
            refIDs.formUnion(tweet.referenced)
        }
        let refTweets: [Tweet] = refIDs.compactMap { id in
            if let tweet = tweets.first(where: {id == $0.id}) {
                return tweet
            } else {
                Swift.debugPrint("Referenced tweet not in discussion with id \(id)")
                return nil
            }
        }
        result.formUnion(refTweets)
        
        /// Remove retweets, but add an ephemeral mark for displaying.
        var toRemove = Set<Tweet>()
        for tweet in result {
            if let rtID = tweet.retweeting {
                toRemove.insert(tweet)
            }
        }
        result.formSymmetricDifference(toRemove)
        
        /// Exclude root tweet.
        result.remove(tweets.first(where: {$0.id == self.id})!)
        
        return result.sorted(by: {$0.id < $1.id})
    }
}

extension Discussion {
    /// Update the last updated date.
    /// - Note: must take place within a `Realm` write transaction.
    func update(with date: Date?) -> Void {
        if let date = date {
            updatedAt = max(updatedAt, date)
        }
    }
    
    /// - Note: must take place within a `Realm` write transaction.
    func patchUpdatedAt() -> Void {
        updatedAt = tweets.map(\.createdAt).max()!
    }
}
