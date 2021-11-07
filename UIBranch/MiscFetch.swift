//
//  MiscFetch.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 6/11/21.
//

import Foundation
import Twig


func fetchOld(airport: Airport, credentials: OAuthCredentials) async -> Void {
    let limitID = UserDefaults.groupSuite.maxID
    guard let rawTweets = try? await timeline(credentials: credentials, sinceID: nil, maxID: limitID) else {
        Swift.debugPrint("Failed to fetch timeline!")
        return
    }
    let ids = rawTweets.map{"\($0.id)"}
    airport.enqueue(ids)
    
    /// Update boundaries.
    let newMaxID = min(rawTweets.map(\.id).min(), Int64?(limitID))
    UserDefaults.groupSuite.maxID = newMaxID.string
    Swift.debugPrint("newMaxID \(newMaxID ?? 0)")
}

func fetchNew(airport: Airport, credentials: OAuthCredentials) async -> Void {
    let limitID = UserDefaults.groupSuite.sinceID
    guard let rawTweets = try? await timeline(credentials: credentials, sinceID: limitID, maxID: nil) else {
        Swift.debugPrint("Failed to fetch timeline!")
        return
    }
    let ids = rawTweets.map{"\($0.id)"}
    airport.enqueue(ids)
    
    /// Update boundaries.
    let newSinceID = max(rawTweets.map(\.id).max(), Int64?(limitID))
    UserDefaults.groupSuite.sinceID = newSinceID.string
    Swift.debugPrint("newSinceID \(newSinceID ?? 0)")
}

fileprivate extension Optional where Wrapped == Int64 {
    init(_ string: String?) {
        if let string = string {
            self = Int64(string)
        } else {
            self = nil
        }
    }
    
    var string: String? {
        if let value = self {
            return "\(value)"
        } else {
            return nil
        }
    }
}

/// Ignore nil value in `max`.
func max<T: Comparable>(_ lhs: T?, _ rhs: T?) -> T? {
    switch (lhs, rhs) {
    case (.some(let lhs), .some(let rhs)):
        return Swift.max(lhs, rhs)
    case (.some(let lhs), .none):
        return lhs
    case (.none, .some(let rhs)):
        return rhs
    case (.none, .none):
        return nil
    }
}

/// Ignore nil value in `min`.
func min<T: Comparable>(_ lhs: T?, _ rhs: T?) -> T? {
    switch (lhs, rhs) {
    case (.some(let lhs), .some(let rhs)):
        return Swift.min(lhs, rhs)
    case (.some(let lhs), .none):
        return lhs
    case (.none, .some(let rhs)):
        return rhs
    case (.none, .none):
        return nil
    }
}
