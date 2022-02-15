//
//  MediaFetcher.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 5/2/22.
//

import Foundation
import Combine
import Twig

final class MediaFetcher {
    /// Set tolerance to 100% to avoid performance issues.
    private let timer = Timer.publish(every: StatusesEndpoint.interval, tolerance: StatusesEndpoint.interval, on: .main, in: .default)
        .autoconnect()
    
    private var observers: Set<AnyCancellable> = []
    
    private let fetchLog: FetchLog = .init()
    
    public static let shared: MediaFetcher = .init()
    private init() {
        let observer = timer.sink { [weak self] _ in
            guard let fetchLog = self?.fetchLog else {
                NetLog.error("Nil error \(#function)")
                return
            }
            
            guard let credentials = Auth.shared.credentials else {
                /// Fails when user is not logged in, simply discard error.
                return
            }
            
            Task {
                let batchIDs: [String] = await fetchLog.next(count: StatusesEndpoint.maxCount)
                guard batchIDs.isNotEmpty else {
                    return
                }
                
                let tweets: [RawV1MediaTweet]
                do {
                    tweets = try await requestMedia(credentials: credentials, ids: batchIDs)
                    assert(tweets.count == batchIDs.count, "Did not receive all requested media tweets!")
                    NetLog.debug("Fetched \(tweets.count) media tweets, ids \(batchIDs.truncated(5))", print: true, true)
                    try ingest(mediaTweets: tweets, fetchLog: fetchLog)
                } catch {
                    NetLog.error("Media fetch failed due to error \(error)")
                    assert(false)
                    
                    await fetchLog.blocklist(ids: batchIDs)
                    
                    return
                }
            }
        }
        observer.store(in: &observers)
    }
    
    deinit {
        for observer in observers {
            observer.cancel()
        }
    }
}

/// Goal: Provide the most recent N tweets not already provided.
fileprivate actor FetchLog {
    
    private var unfetchableIDs: Set<Tweet.ID> = []
    public func blocklist<TweetCollection: Collection>(ids: TweetCollection) -> Void where TweetCollection.Element == Tweet.ID {
        unfetchableIDs.formUnion(ids)
    }
    
    public func next(count: Int = StatusesEndpoint.maxCount) -> [Tweet.ID] {
        var result: [Tweet.ID] = []
        let unfetched = makeRealm()
            .objects(Tweet.self)
            .filter(Tweet.missingMediaPredicate)
        
        /// Tracks requested ranges.
        var cursor = 0
        
        while result.count < count {
            let nextPageRange = cursor..<min(cursor + count, unfetched.count)
            let pageIDs = unfetched[nextPageRange].map(\.id)
            let newIDs = pageIDs.filter({ id in
                self.unfetchableIDs.contains(id) == false
            })
            result.append(contentsOf: newIDs)
            
            /// If there is no next page, stop.
            if nextPageRange.upperBound == unfetched.count { break }
            
            cursor += count
        }
        
        /// Trim results to size.
        if result.count > count {
            result = Array(result[0..<count])
        }
        
        return result
    }
    
    #if DEBUG
    public func unfetchedCount() -> Int {
        makeRealm()
            .objects(Tweet.self)
            .filter(Tweet.missingMediaPredicate)
            .count
    }
    #endif
}

fileprivate func ingest(mediaTweets: [RawV1MediaTweet], fetchLog: FetchLog) throws -> Void {
    let realm = makeRealm()
    try realm.writeWithToken { token in
        for mediaTweet in mediaTweets {
            /// Handle errors individually, instead of bringing down the entire set of insertions.
            do {
                guard let tweet = realm.tweet(id: mediaTweet.id_str) else {
                    throw HTRealmError.unexpectedNilFromID(mediaTweet.id_str)
                }
                try tweet.addVideo(token: token, from: mediaTweet)
            } catch MediaIngestError.advertiserMedia {
                Task {
                    await fetchLog.blocklist(ids: [mediaTweet.id_str])
                }
                continue
            } catch {
                ModelLog.error("""
                    Video could not be added due to error \(error)
                    - id: \(mediaTweet.id_str)
                    - data: \(mediaTweet)
                    """)
                assert(false)
                
                Task {
                    await fetchLog.blocklist(ids: [mediaTweet.id_str])
                }
                continue
            }
        }
    }
}

enum MediaIngestError: Error {
    /// Entities was not returned or could not be parsed.
    case missingEntities
    
    case missingMediaID
    
    case mismatchedMediaID
    
    /// Advertiser videos are not provided to APIs.
    /// Example tweet: https://twitter.com/PA/status/1493239875952418820
    /// Docs: https://developer.twitter.com/en/docs/twitter-api/v1/data-dictionary/object-model/extended-entities
    case advertiserMedia
}
