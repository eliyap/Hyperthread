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
                NetLog.error("Nil credentials \(#function)")
                return
            }
            
            let batchIDs: [String] = fetchLog.next(count: StatusesEndpoint.maxCount)
            guard batchIDs.isNotEmpty else { return }
            
            Task {
                let tweets = try! await requestv11Statuses(credentials: credentials, ids: batchIDs)
                print("Fetched \(tweets.count)")
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
        .filter(NSPredicate(format: """
            SUBQUERY(\(Tweet.mediaPropertyName), $m,
                $m.\(Media.typePropertyName) == \(MediaType.animated_gif.rawValue)
             OR $m.\(Media.typePropertyName) == \(MediaType.video.rawValue)
            ).@count > 0
            """))
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
