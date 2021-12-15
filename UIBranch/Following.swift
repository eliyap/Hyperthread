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
        didSet {
            UserDefaults.groupSuite.followingIDs = ids
        }
    }
    
    /** Fetches are limited to ~1/min. Therefore, only declare data stale after 90s.
        Docs: https://developer.twitter.com/en/docs/twitter-api/users/follows/api-reference/get-users-id-following
     */
    static let stalenessThreshhold: TimeInterval = 90
    var isStale: Bool {
        let lastFetched = UserDefaults.groupSuite.followingUpdated ?? Date.distantPast
        let timeSinceFetch = Date().timeIntervalSince(lastFetched)
        return timeSinceFetch > Self.stalenessThreshhold
    }
    
    private init() {
        /// Load pre-existing IDs from UserDefaults.
        self.ids = UserDefaults.groupSuite.followingIDs
    }
}

fileprivate extension UserDefaults {
    static let followingIDsKey = "followingIDs"
    var followingIDs: [String]? {
        get {
            return array(forKey: Self.followingIDsKey) as? [String]
        }
        set {
            set(newValue, forKey: Self.followingIDsKey)
        }
    }
    
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
