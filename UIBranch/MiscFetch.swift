//
//  MiscFetch.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 6/11/21.
//

import Foundation
import Twig

func updateFollowing(credentials: OAuthCredentials) async -> Void {
    do {
        let rawUsers = try await requestFollowing(credentials: credentials)
        NetLog.log(items: "Successfully fetched \(rawUsers.count) following users.")
        UserDefaults.groupSuite.followingIDs = rawUsers.map(\.id)
    } catch {
        fatalError(error.localizedDescription)
    }
}

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
