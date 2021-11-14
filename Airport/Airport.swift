//
//  Airport.swift
//  BranchRealm
//
//  Created by Secret Asian Man Dev on 31/10/21.
//

import Foundation
import Combine
import Twig

/**
 Organizes requests for Tweets so that they are dispatched in an orderly, yet timely fasion.
 */
final class Airport {
    
    /// - Note: tolerance set to 100% to prevent performance hits.
    /// Docs: https://developer.apple.com/documentation/foundation/timer/1415085-tolerance
    private let timer = Timer.publish(every: 0.2, tolerance: 0.2, on: .main, in: .default)
        .autoconnect()
    
    /// Tweets currently being requested.
    private var inFlight = Set<Tweet.ID>()
    
    private let queue = PassthroughSubject<Tweet.ID, Never>()
    
    private var x: AnyCancellable? = nil
    
    init(credentials: OAuthCredentials) {
        x = queue
            .buffer(size: 100, timer)
            /// Send work to background.
            .subscribe(on: DispatchQueue.global())
            .filter(\.isNotEmpty)
            .asyncMap { (ids: [Tweet.ID]) in
                NetLog.log(items: "Fetching \(ids.count) IDs")
                return try await hydratedTweets(
                    credentials: credentials,
                    ids: ids,
                    fields: RawHydratedTweet.fields,
                    expansions: RawHydratedTweet.expansions
                )
            }
            .map { [weak self] (tweets: [RawHydratedTweet], users: [RawIncludeUser]) in
                /// Remove from in-flight list.
                tweets.forEach { self?.inFlight.remove($0.id) }
                return (tweets, users)
            }
            .tryMap(furtherFetch)
            .map { ids in
                self.enqueue(ids) /// Recursive step.
                return ids
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    Swift.debugPrint(error)
                    fatalError(error.localizedDescription)
                case .finished:
                    fatalError("Should not finish")
                }
            }, receiveValue: { (ids: Set<Tweet.ID>) in
                print("Fetched \(ids.count) ids")
            })
    }
    
    /// Add `id` to list of tweets waiting to be fetched.
    public func enqueue(_ id: Tweet.ID) -> Void {
        guard inFlight.contains(id) == false else {
            return
        }
        inFlight.insert(id)
        queue.send(id)
    }
    
    /// Add `ids` to list of tweets waiting to be fetched.
    public func enqueue<T: Collection>(_ ids: T) -> Void where T.Element == Tweet.ID {
        ids.forEach { enqueue($0) }
    }
}

extension Array {
    var isNotEmpty: Bool {
        !isEmpty
    }
}
