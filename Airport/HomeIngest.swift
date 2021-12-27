//
//  HomeIngest.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 23/12/21.
//

import Foundation
import Combine
import RealmSwift
import Twig

/// An object wrapping a Combine data processing "pipeline".
/// Takes care of the oft-forgotten step of cancelling the `AnyCancellable`.
public class Conduit<Input, Failure: Error> {
    public var pipeline: AnyCancellable? = nil
    public let intake: PassthroughSubject<Input, Failure> = .init()
    public init() {}
    deinit {
        pipeline?.cancel()
        pipeline = nil
    }
}

final class HomeIngest<T: HomeTimelineFetcher>: Conduit<Void, Never> {
    
    /// - Note: tolerance set to 100% to prevent performance hits.
    /// Docs: https://developer.apple.com/documentation/foundation/timer/1415085-tolerance
    private let timer = Timer.publish(every: 0.05, tolerance: 0.05, on: .main, in: .default)
        .autoconnect()
    
    /// Conduit Object with which to request follow up fetches.
    weak var followUp: FollowUp?
    
    /// Completion handlers to be executed and discarded when a fetch completes successfully.
    private var onFetched: [() -> Void] = []
    
    public init(followUp: FollowUp) {
        super.init()
        self.followUp = followUp
        
        let fetcher = T()
        
        /// When requested, publishes the IDs of new tweets on the home timeline.
        self.pipeline = intake
            /// Only proceed if credentials are loaded.
            .compactMap { Auth.shared.credentials }
            .asyncMap { (credentials) -> [RawV1Tweet] in
                do {
                    return try await fetcher.fetchTimeline(credentials: credentials)
                } catch {
                    NetLog.error("\(error)")
                    assert(false, "\(error)")
                    return []
                }
            }
            /// Convert to strings
            .map { [weak self] ids in
                /// Fire completion early if home timeline returns nothing.
                /// This prevents the "empty" filter in `v2Fetch` from swallowing stuff.
                if ids.isEmpty {
                    self?.removeAll()
                }
                return ids.map{ "\($0.id)" }
            }
            .v2Fetch()
            /// Synchronize
            .receive(on: Airport.scheduler)
            .sink(receiveValue: { [weak self] (tweets, _, users, media) in
                do {
                    NetLog.debug("Received \(tweets.count) home timeline tweets.", print: true, true)
                    try ingestRaw(rawTweets: tweets, rawUsers: users, rawMedia: media, relevance: .discussion)
                    
                    /// Update home timeline boundaries.
                    fetcher.updateBoundaries(tweets: tweets)
                    
                    /// Immediately check for follow up.
                    followUp.intake.send()
                    
                    self?.removeAll()
                } catch {
                    ModelLog.error("\(error)")
                    assert(false, "\(error)")
                }
            })
    }
    
    public func add(_ completion: @escaping () -> Void) -> Void {
        onFetched.append(completion)
    }
    
    private func removeAll() -> Void {
        /// Execute and remove completion handlers.
        onFetched.forEach { $0() }
        onFetched = []
    }
}
