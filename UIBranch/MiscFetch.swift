//
//  MiscFetch.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 6/11/21.
//

import Foundation
import Twig

func updateFollowing(credentials: OAuthCredentials) async -> Void {
    do {
        let rawUsers = try await requestFollowing(credentials: credentials)
        NetLog.debug("Successfully fetched \(rawUsers.count) following users.", print: true, true)
        
        /// Update in-memory store.
        Following.shared.ids = rawUsers.map(\.id)
    } catch {
        fatalError(error.localizedDescription)
    }
}
