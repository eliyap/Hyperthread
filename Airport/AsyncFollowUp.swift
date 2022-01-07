//
//  AsyncFollowUp.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 7/1/22.
//

import Foundation
import Twig
import RealmSwift
import Algorithms

/// An error we can surface to the user.
/// *Not* an error on the user's part.
public enum UserError: Error {
    case fetch(Error)
    case credentials
    case database
}

actor ReferenceCrawler {
    
    private var inFlight: Set<Tweet.ID> = []
    
    private func fetch(ids: [Tweet.ID]) async -> Result<Void, UserError> {
        guard let credentials = Auth.shared.credentials else {
            return .failure(.credentials)
        }
        
        var rawData: RawData
        var followingIDs: [User.ID]
        do {
            /// Dispatch requests in parallel.
            async let _rawData = hydratedTweets(credentials: credentials, ids: ids)
            async let _followingIDs = FollowingCache.shared.request()
            (rawData, followingIDs) = try await (_rawData, _followingIDs)
        } catch {
            NetLog.error("Follow up fetch error: \(error)")
            return .failure(.fetch(error))
        }
        
        /// Unbundle tuple.
        let (tweets, _, users, _) = rawData
        
        /// Remove tweets from list.
        for tweet in tweets {
            inFlight.remove(tweet.id)
        }
        do {
            try Self.store(rawData: rawData, followingIDs: followingIDs)
        } catch {
            return .failure(.database)
        }
        
        /// Dispatch task for missing users. Not necessary to continue iterating.
        Task {
            await withTaskGroup(of: Void.self) { group in
                findMissingMentions(tweets: tweets, users: users)
                    .chunks(ofCount: UserEndpoint.maxResults)
                    .forEach { chunk in
                        group.addTask {
                            await UserFetcher.fetchAndStoreUsers(ids: Array(chunk))
                        }
                    }
            }
        }
        
        return .success(Void())
    }
    
    /// Perform `Realm` work to store the fetched data.
    private static func store(rawData: RawData, followingIDs: [User.ID]) throws -> Void {
        /// Unbundle tuple.
        let (tweets, included, users, media) = rawData
        
        /// Safe to insert `included`, as we make no assumptions around `Relevance`.
        try ingestRaw(rawTweets: tweets + included, rawUsers: users, rawMedia: media, following: followingIDs)
        
        let realm = try! Realm()
        try realm.updateDangling()
    }
}

