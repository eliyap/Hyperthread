//
//  OnUnfollow.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 5/1/22.
//

import Foundation
import Twig
import RealmSwift

internal func onUnfollow(userIDs: [User.ID]) -> Void {
    func onUnfollow(userID: User.ID) -> Void {
        let realm = try! Realm()
        do {
            try realm.writeWithToken { token in
                /// Upgrade relevance so that existing tweets are *not* surfaced.
                realm.updateRelevanceOnUnfollow(token, userID: userID)
                
                guard let user = realm.user(id: userID) else {
                    throw RealmError.missingObject
                }
                
                /// Update following status.
                user.following = false
            }
        } catch {
            ModelLog.error("Failed to update storage after follow! Error: \(error)")
            assert(false)
        }
    }
    
    /// Do `try-catch` memberwise, so that one `throw` does not prevent other `User`s being updated.
    for userID in userIDs {
        onUnfollow(userID: userID)
    }
}
