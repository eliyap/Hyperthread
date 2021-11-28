//
//  Storage.swift
//  Branch
//
//  Created by Secret Asian Man Dev on 16/10/21.
//

import Foundation
import Twig

extension UserDefaults {
    static var groupSuite = UserDefaults(suiteName: "group.com.twitter.branch")!
    
    enum Keys: String {
        case oAuthCredentials
    }
    
    var oAuthCredentials: OAuthCredentials? {
        get {
            guard let data = object(forKey: Keys.oAuthCredentials.rawValue) as? Data else {
                Swift.debugPrint("No OAuth credentials found.")
                return nil
            }
            guard let loaded = try? JSONDecoder().decode(OAuthCredentials.self, from: data) else {
                assert(false, "Could not decode credentials!")
                return nil
            }
            return loaded
        }
        set {
            guard let encoded = try? JSONEncoder().encode(newValue) else {
                assert(false, "Could not encode!")
                return
            }
            set(encoded, forKey: Keys.oAuthCredentials.rawValue)
        }
    }

    /// Docs: https://developer.twitter.com/en/docs/twitter-api/v1/tweets/timelines/guides/working-with-timelines
    fileprivate static let sinceIDKey = "sinceID"
    var sinceID: String? {
        get {
            return string(forKey: Self.sinceIDKey)
        }
        set {
            set(newValue, forKey: Self.sinceIDKey)
        }
    }

    /// - Note: **only** update this value with tweets from a user's actual timeline, NOT follow up fetches!
    /// Docs: https://developer.twitter.com/en/docs/twitter-api/v1/tweets/timelines/guides/working-with-timelines
    fileprivate static let maxIDKey = "maxID"
    var maxID: String? {
        get {
            return string(forKey: Self.maxIDKey)
        }
        set {
            set(newValue, forKey: Self.maxIDKey)
        }
    }

    fileprivate static let followingIDsKey = "followingIDs"
    var followingIDs: [String]? {
        get { 
            return array(forKey: Self.followingIDsKey) as? [String]
        }
        set {
            set(newValue, forKey: Self.followingIDsKey)
        }
    }

    /// - Note: use `object(forKey: )` instead of `integer(forKey: )` because it returns `nil` instead of `0`.
    /// Docs: https://developer.apple.com/documentation/foundation/nsdictionary/1414347-object
    fileprivate static let scrollPositionID = "scrollPosition"
    var scrollPosition: Int? {
        get {
            return object(forKey: Self.scrollPositionID) as? Int
        }
        set {
            set(newValue, forKey: Self.scrollPositionID)
        }
    }
    
    /// Returns whether the operation was successful.
    @discardableResult
    func incrementScrollPosition() -> Bool {
        guard let val = scrollPosition else { return false }
        scrollPosition = val + 1
        return true
    }
}

final class SharedAuth: ObservableObject {
    @Published public var cred: OAuthCredentials? = nil
    
    init() {
        cred = UserDefaults.groupSuite.oAuthCredentials
    }
}
