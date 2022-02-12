//
//  Airport.swift
//  BranchRealm
//
//  Created by Secret Asian Man Dev on 31/10/21.
//

import Foundation
import Combine
import Twig
import RealmSwift

internal func fetchAndStoreUsers(ids: [User.ID]) async -> Void {
    /// Only proceed if credentials are loaded.
    guard let credentials = Auth.shared.credentials else {
        NetLog.error("Tried to load users without credentials!")
        assert(false)
        return
    }
    
    var rawUsers: [RawUser] = []
    do {
        rawUsers = try await users(userIDs: ids, credentials: credentials)
    } catch {
        NetLog.error("User Endpoint fetch failed with error \(error)")
        assert(false)
        return
    }
    
    NetLog.debug("Received \(rawUsers.count) users")
    
    let realm = makeRealm()
    do {
        try realm.writeWithToken { token in
            for rawUser in rawUsers {
                /// Defer to local database, otherwise assume false.
                let isFollowing = realm.user(id: rawUser.id)?.following ?? false
                
                let user = User(raw: rawUser, following: isFollowing)
                realm.add(user, update: .modified)
            }
        }
    } catch {
        ModelLog.error("Failed to store users with error \(error)")
        assert(false)
    }
}
