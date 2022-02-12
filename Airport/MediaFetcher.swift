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
            
            let batchIDs: [String] = fetchLog.next(count: StatusesEndpoint.maxCount)
            guard batchIDs.isNotEmpty else { return }
            
            Task {
                let tweets = try! await requestMedia(credentials: credentials, ids: batchIDs)
                NetLog.debug("Fetched \(tweets.count) media tweets", print: true, true)
                ingest(mediaTweets: tweets)
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
fileprivate final class FetchLog {
    private let unfetched = makeRealm()
        .objects(Tweet.self)
        .filter(Tweet.missingMediaPredicate)
    
    var provided: Set<Tweet.ID> = []
    
    func next(count: Int = StatusesEndpoint.maxCount) -> [Tweet.ID] {
        var result: [Tweet.ID] = []
        
        /// Tracks requested ranges.
        var cursor = 0
        
        while result.count < count {
            let nextPageRange = cursor..<min(cursor + count, unfetched.count)
            let pageIDs = unfetched[nextPageRange].map(\.id)
            let newIDs = pageIDs.filter({ id in
                self.provided.contains(id) == false
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
        
        provided.formUnion(result)
        return result
    }
}

fileprivate func ingest(mediaTweets: [RawV1MediaTweet]) -> Void {
    let realm = makeRealm()
    
    do {
        try realm.writeWithToken { token in
            for mediaTweet in mediaTweets {
                /// Handle errors individually, instead of bringing down the entire set of insertions.
                do {
                    guard let tweet = realm.tweet(id: mediaTweet.id_str) else {
                        throw HTRealmError.unexpectedNilFromID(mediaTweet.id_str)
                    }
                    try tweet.addVideo(token: token, from: mediaTweet)
                } catch {
                    ModelLog.error("Video could not be added due to error \(error)")
                    assert(false)
                    continue
                }
            }
        }
    } catch {
        ModelLog.error("Error during media ingest \(error)")
        assert(false)
    }
}

enum MediaIngestError: Error {
    /// Entities was not returned or could not be parsed.
    case missingEntities
    
    case missingMediaID
    
    case mismatchedMediaID
}
