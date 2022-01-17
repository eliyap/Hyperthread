//
//  BigFetch.swift
//  BranchRealm
//
//  Created by Secret Asian Man Dev on 31/10/21.
//

import Foundation
import RealmSwift
import Twig

/**
 Accepts raw data from the Twitter v2 API, including `included` tweets,
 */
func ingestRaw(
    rawTweets: [RawHydratedTweet],
    rawUsers: [RawUser],
    rawMedia: [RawIncludeMedia],
    following: [User.ID]
) throws -> Void {
    let realm = try! Realm()
    
    /// Insert all users.
    try realm.write {
        for rawUser in rawUsers {
            let following = following.contains(where: {$0 == rawUser.id})
            let user = User(raw: rawUser, following: following)
            realm.add(user, update: .modified)
        }
    }
    
    /// Reject tweets with missing media (usually happens because they were "included".
    let mediaKeys = rawMedia.map(\.media_key)
    let rawTweets = rawTweets.filter { rawTweet in
        /// If keys exist, check they are all present.
        guard let keys = rawTweet.attachments?.media_keys else { return true }
        return keys.allSatisfy { mediaKeys.contains($0) }
    }
    
    /// Insert Tweets into local database.
    try realm.writeWithToken { token in
        for rawTweet in rawTweets {
            let prior = realm.tweet(id: rawTweet.id)
            
            /// Check `relevance` value in Realm, to avoid ovewriting an existing value (if any).
            let checkedRelevance = prior?.relevance ?? Relevance(tweet: rawTweet, following: following)
            
            /// Check for existing`read`. If none, mark read if this is the first run.
            let checkedRead = prior?.read ?? UserDefaults.groupSuite.firstFetch
            
            let tweet: Tweet = Tweet(raw: rawTweet, rawMedia: rawMedia, relevance: checkedRelevance, read: checkedRead)
            
            realm.add(tweet, update: .modified)
            
            /// Safety check: we count on the user never being missing!
            if realm.user(id: rawTweet.author_id) == nil {
                fatalError("Could not find user with id \(rawTweet.author_id)")
            }
            
            /// Attach to conversation (create one if necessary).
            realm.linkTweet(token, tweet: tweet)
        }
    }
}

/**
 Store tweets from Twitter's v1.1 home timeline endpoint.
 - Note: we do not need following user IDs to determine relevance, as we set _all_ home timeline tweets to the highest relevance.
 - Warning: Do not feed `include`d `Tweet`s!
            These may be missing media keys, or be of a different `Relevance` than the main payload!
 */
func ingestRawHomeTimelineTweets(
    rawTweets: [RawHydratedTweet],
    rawUsers: [RawUser],
    rawMedia: [RawIncludeMedia]
) throws -> Void {
    /// Set all home timeline tweets to the highest relevance.
    let relevance: Relevance = .discussion
    
    let realm = try! Realm()
    
    /// Insert all users.
    try realm.write {
        for rawUser in rawUsers {
            /// Check `following` status in Realm, to avoid overwriting an existing value (if any).
            /// If none, assume we do not follow the user.
            let following = realm.user(id: rawUser.id)?.following ?? false
            
            let user = User(raw: rawUser, following: following)
            realm.add(user, update: .modified)
        }
    }
    
    /// Insert Tweets into local database.
    try realm.writeWithToken { token in
        for rawTweet in rawTweets {
            /// Check for existing`read`. If none, mark read if this is the first run.
            let checkedRead = realm.tweet(id: rawTweet.id)?.read ?? UserDefaults.groupSuite.firstFetch
            
            /// - Note: **intentionally** overwrite existing `relevance`, which may have resulted
            ///         from user timeline fetch.
            let tweet: Tweet = Tweet(raw: rawTweet, rawMedia: rawMedia, relevance: relevance, read: checkedRead)
            realm.add(tweet, update: .modified)
            
            /// Safety check: we count on the user never being missing!
            if realm.user(id: rawTweet.author_id) == nil {
                fatalError("Could not find user with id \(rawTweet.author_id)")
            }
            
            /// Attach to conversation (create one if necessary).
            realm.linkTweet(token, tweet: tweet)
        }
    }
}
