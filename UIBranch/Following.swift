//
//  Following.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 13/11/21.
//

import Foundation

/// Singleton tracking which user's the user follows.
final class Following {
    
    public static let shared = Following()
    
    public var ids: [User.ID]? {
        /// Store values locally.
        didSet {
            UserDefaults.groupSuite.followingIDs = ids
            UserDefaults.groupSuite.followingUpdated = Date()
        }
    }
    
    /** Fetches are limited to ~1/min. Therefore, only declare data stale after 90s.
        Docs: https://developer.twitter.com/en/docs/twitter-api/users/follows/api-reference/get-users-id-following
     */
    static let stalenessThreshhold: TimeInterval = 90
    var isStale: Bool {
        /// If no data is available, consider the data **very** stale.
        guard self.ids != nil else { return true }
        let lastFetched = UserDefaults.groupSuite.followingUpdated ?? Date.distantPast
        
        let timeSinceFetch = Date().timeIntervalSince(lastFetched)
        return timeSinceFetch > Self.stalenessThreshhold
    }
    
    /// "Invalidate" UserIDs by marking the value as very stale.
    public func forceStale() -> Void {
        UserDefaults.groupSuite.followingUpdated = .distantPast
    }
    
    private init() {
        /// Load pre-existing IDs from UserDefaults.
        self.ids = UserDefaults.groupSuite.followingIDs
    }
}

// MARK: - Storage
fileprivate extension UserDefaults {
    /** UserIDs of the Twitter users our user follows.
     */
    var followingIDs: [String]? {
        get {
            return array(forKey: #function) as? [String]
        }
        set {
            set(newValue, forKey: #function)
        }
    }
    
    /** Tracks the last time the following list was updated. */
    var followingUpdated: Date? {
        get {
            guard let data = object(forKey: #function) as? Data else {
                return nil
            }
            guard let loaded = try? JSONDecoder().decode(Date.self, from: data) else {
                assert(false, "Could not decode date!")
                return nil
            }
            return loaded
        }
        set {
            guard let encoded = try? JSONEncoder().encode(newValue) else {
                assert(false, "Could not encode!")
                return
            }
            set(encoded, forKey: #function)
        }
    }
}
