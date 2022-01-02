//
//  FollowUp.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 23/12/21.
//

import Foundation
import Combine
import RealmSwift
import Twig

final class FollowUp: Conduit<Void, Never> {
    /// An additional "intake" for follow up on follow up.
    public let recycle = PassthroughSubject<[Tweet.ID], Never>()
    
    override init() {
        super.init()
        var inFlight: Set<Tweet.ID> = []
        
        let intakePublisher = intake
            /// Synchronize
            .receive(on: Airport.scheduler)
            .map { (_) -> Set<Tweet.ID> in
                let realm = try! Realm()
                var toFetch: Set<Tweet.ID> = []
                
                let c = realm.conversationsWithFollowUp()
                toFetch.formUnion(c
                    .map { $0.getFollowUp(realm: realm) }
                    .reduce(Set<Tweet.ID>()) { $0.union($1) }
                )
                
                let d = realm.discussionsWithFollowUp()
                toFetch.formUnion(d
                    .map { $0.getFollowUp() }
                    .reduce(Set<Tweet.ID>()) { $0.union($1) }
                )
                
                NetLog.debug("\(c.count) conversations, \(d.count) discussions requiring follow up.", print: true, true)
                return toFetch
            }
            .map { Array($0) }
        
        self.pipeline = intakePublisher.merge(with: recycle)
            .map {
                $0.filter { inFlight.contains($0) == false }
            }
            .map { (ids: [Tweet.ID]) -> [Tweet.ID] in
                inFlight.formUnion(ids)
                NetLog.debug("Requesting \(ids.count) tweets", print: true, true)
                return ids
            }
            .v2Fetch()
            /// Synchronize
            .receive(on: Airport.scheduler)
            .joinFollowing()
            .sink { [weak self] data, following in
                let (tweets, included, users, media) = data
                do {
                    /// Safe to insert `included`, as we make no assumptions around `Relevance`.
                    try ingestRaw(rawTweets: tweets + included, rawUsers: users, rawMedia: media, following: following)
                    
                    /// Remove tweets from list.
                    for tweet in tweets {
                        inFlight.remove(tweet.id)
                    }
                    NetLog.debug("Follow up has \(inFlight.count) in flight.", print: true, true)
                    
                    let realm = try! Realm()
                    try realm.updateDangling()
                    
                    /// Perform linking and request follow up.
                    let toRecycle = try linkUnlinked()
                    self?.recycle.send(Array(toRecycle))
                    
                    /// Check for further follow up.
                    self?.intake.send()
                } catch {
                    ModelLog.error("\(error)")
                    assert(false, "\(error)")
                }
            }
    }
}

public typealias RawData = ([RawHydratedTweet], [RawHydratedTweet], [RawUser], [RawIncludeMedia])
extension Publisher where Output == [Tweet.ID], Failure == Never {
    func v2Fetch() -> AnyPublisher<RawData, Never> {
        /// - Note: tolerance set to 100% to prevent performance hits.
        /// Docs: https://developer.apple.com/documentation/foundation/timer/1415085-tolerance
        let timer = Timer.publish(every: 0.05, tolerance: 0.05, on: .main, in: .default)
            .autoconnect()
        
        return self
            .flatMap { $0.publisher }
            .buffer(size: UInt(TweetEndpoint.maxResults), timer)
            .filter(\.isNotEmpty)
            /// Only proceed if credentials are loaded.
            .compactMap{ (ids: [Tweet.ID]) -> ([Tweet.ID], OAuthCredentials)? in
                if let credentials = Auth.shared.credentials {
                    return (ids, credentials)
                } else {
                    return nil
                }
            }
            .asyncMap { (ids, credentials) -> ([RawHydratedTweet], [RawHydratedTweet], [RawUser], [RawIncludeMedia]) in
                do {
                    return try await hydratedTweets(credentials: credentials, ids: ids)
                } catch {
                    NetLog.error("\(error)")
                    assert(false, "\(error)")
                    return ([], [], [], [])
                }
            }
            .eraseToAnyPublisher()
    }
}

extension Publisher {
    func joinFollowing() -> Publishers.FlatMap<Future<(Output, [User.ID]), Failure>, Self> {
        flatMap { (value: Output) in
            Future { promise  in
                Task<Void, Never> {
                    await FollowingClearingHouse.shared.request { ids in
                        promise(.success((value, ids)))
                    }
                }
            }
        }
    }
}

/// Centralized reference for following, to avoid multiple fetchers pummeling the API.
fileprivate actor FollowingClearingHouse {
    public typealias Output = [User.ID]
    public typealias Handler = (Output) -> ()
    
    /// Memoized Output.
    private let local: Sealed<Output> = .init(initial: nil, timer: FollowingEndpoint.staleTimer)
    
    /// Completion handlers for when the fetch returns.
    private var queue: [Handler] = []
    
    /// Whether a request is currently in progress.
    private var isFetching: Bool = false
    
    /// Singleton Class.
    public static let shared: FollowingClearingHouse = .init()
    private init(){}
    
    public func request(handler: @escaping Handler) async -> Void {
        if let stored = await local.value {
            handler(stored)
        } else {
            queue.append(handler)
            await dispatch()
        }
    }
    
    private func dispatch() async -> Void {
        guard isFetching == false else { return }
        isFetching = true
        
        let output: Output = await fetch()
        
        /// Call and release closures.
        queue.forEach { $0(output) }
        queue = []
        
        /// Memoize fresh value.
        await local.seal(output)
        
        isFetching = false
    }
    
    private func fetch() async -> Output {
        
        NetLog.debug("Following API request dispatched at \(Date())", print: true, true)
        
        /// Assume credentials are available.
        guard let credentials = Auth.shared.credentials else {
            NetLog.error("Tried to fetch, but credentials missing!")
            assert(false)
            return []
        }
        
        guard let rawUsers = try? await requestFollowing(credentials: credentials) else {
            NetLog.error("Failed to fetch following list!")
            assert(false)
            
            /// If the fetch fails, fall back on local Realm storage.
            let realm = try! await Realm()
            let ids: [User.ID] = realm.objects(User.self)
                .filter("\(User.followingPropertyName) == YES")
                .map(\.id)
            return ids
        }
        
        NetLog.debug("Successfully fetched \(rawUsers.count) following users", print: true, true)
        
        /// Store fetched results.
        do {
            let realm = try! await Realm()
            try realm.storeFollowing(raw: Array(rawUsers))
            return rawUsers.map(\.id)
        } catch {
            NetLog.error("Failed to store following list!")
            assert(false, "Failed to store following list!")
            return []
        }
    }
}
