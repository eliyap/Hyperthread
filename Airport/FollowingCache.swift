//
//  UserTimelineFetch.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 4/1/22.
//

import Foundation
import Twig
import RealmSwift

/** A centralized point for getting the ids of `User`s which our user follows.

    This actor uses checked continuations to permit multiple requests 
    to wait on a single network fetch operation.
    This prevents multiple requests from causing a 429 error.
 */
actor FollowingCache {
    
    typealias Output = [User.ID]
    
    /// Cached value. Automatically expires after a set period of time.
    private let cache: Sealed<Output> = .init(initial: nil, timer: FollowingEndpoint.staleTimer)
    
    /// Stored continuations for when the fetch request returns.
    private var continuations: [CheckedContinuation<Output, Never>] = []
    
    /// Whether a request is currently in progress.
    private var isFetching: Bool = false
    
    /// Singleton object.
    public static let shared: FollowingCache = .init()
    private init() {}
    
    /// Return the cached value, if any
    public func request() async -> Output {
        if let cached = await cache.value {
            return cached
        } else {
            return await withCheckedContinuation { continuation in
                continuations.append(continuation)
                Task { await dispatch() }
            }
        }
    }

    /// Start a fetch operation if one is not already in progress.
    /// Execute all continuations when the fetch completes.
    private func dispatch() async -> Void {
        guard isFetching == false else { return }
        isFetching = true
        
        let output: Output = await fetch()
        
        /// Call and discard continuations.
        continuations.forEach { $0.resume(returning: output) }
        continuations = []
        
        /// Memoize fresh value.
        await cache.seal(output)
        
        isFetching = false
    }
    
    /// Perform a network fetch, falling back on local database storage if that fails.
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
            let realm = makeRealm()
            let ids: [User.ID] = realm.objects(User.self)
                .filter("\(User.followingPropertyName) == YES")
                .map(\.id)
            return ids
        }
        
        NetLog.debug("Fetched \(rawUsers.count) following users", print: true, true)
        
        /// Synchronous context.
        return {
            /// Store fetched results.
            do {
                let realm = makeRealm()
                try realm.storeFollowing(raw: rawUsers)
                return rawUsers.map(\.id)
            } catch {
                NetLog.error("Failed to store following list!")
                assert(false, "Failed to store following list!")
                return []
            }
        }()
    }
}
