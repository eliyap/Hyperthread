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
        
        /// Store on disk.
        UserDefaults.groupSuite.followingIDs = rawUsers.map(\.id)
        
        /// Update in-memory store.
        Following.shared.ids = rawUsers.map(\.id)
    } catch {
        fatalError(error.localizedDescription)
    }
}
