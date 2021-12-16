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
    /**
     - Important: Tech Note. Using `.subscribe(on: DispatchQueue.global())`
       to "background" work, caused the first fetch (containing the most recent ~100 tweets) to "go missing".
       Avoid this method for now.
     */
    
    /// - Note: tolerance set to 100% to prevent performance hits.
    /// Docs: https://developer.apple.com/documentation/foundation/timer/1415085-tolerance
    private let timer = Timer.publish(every: 0.2, tolerance: 0.2, on: .main, in: .default)
        .autoconnect()
    
    /// Tweets currently being requested.
    private var inFlight = Set<Tweet.ID>()
    
    private let queue = PassthroughSubject<Tweet.ID, Never>()
    
    /// The core of the object. Represents our data flow.
    private var pipeline: AnyCancellable? = nil
    
    /** The scheduler on which work is done.
        
        Because `Realm` write transactions are done in our pipeline,
        and write transactions block other work,
        it is critical that we allow other threads to avoid conflict with `Airport`.
     
        Chosen based on article: https://www.avanderlee.com/combine/runloop-main-vs-dispatchqueue-main/
     */
    public static let scheduler = DispatchQueue.main
    
    init(credentials: OAuthCredentials) {
        let chunkPublisher: AnyPublisher<([RawHydratedTweet], [RawIncludeUser], [RawIncludeMedia]), Error> = queue
            .buffer(size: 100, timer)
            .filter(\.isNotEmpty)
            .asyncMap { (ids: [Tweet.ID]) in
                NetLog.debug("Fetching \(ids.count) IDs")
                return try await hydratedTweets(
                    credentials: credentials,
                    ids: ids,
                    fields: RawHydratedTweet.fields,
                    expansions: RawHydratedTweet.expansions,
                    mediaFields: RawHydratedTweet.mediaFields
                )
            }
            /// Remove from in-flight list.
            .map { [weak self] (tweets: [RawHydratedTweet], users: [RawIncludeUser], media: [RawIncludeMedia]) in
                tweets.forEach { self?.inFlight.remove($0.id) }
                print("Fetched \(tweets.count) tweets. \(self?.inFlight.count ?? -1) still in flight.")
                return (tweets, users, media)
            }
            .receive(on: Self.scheduler, options: nil)
            .eraseToAnyPublisher()
        
        /// - Note: Splitting the pipeline prevents an inscrutable error where
        ///         Swift's type inference appeared to collapse. (21.12.16)
        pipeline = chunkPublisher
            .tryMap({ (tweets, users, media) -> Set<Tweet.ID> in
                let setA = try furtherFetch(rawTweets: tweets, rawUsers: users, rawMedia: media)
                let setB = try linkOrphans()
                return setA.union(setB)
            })
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
            }, receiveValue: { (_: Set<Tweet.ID>) in
                /// Nothing.
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

extension Collection {
    var isNotEmpty: Bool {
        !isEmpty
    }
}
