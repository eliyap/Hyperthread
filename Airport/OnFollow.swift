//
//  OnFollow.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 5/1/22.
//

import Foundation
import Twig
import RealmSwift

internal func onFollow(userIDs: [User.ID]) -> Void {
    func onFollow(userID: User.ID) -> Void {
        let realm = try! Realm()
        do {
            try realm.writeWithToken { token in
                /// Upgrade relevance so that existing tweets are surfaced.
                realm.updateRelevanceOnFollow(token, userID: userID)
                
                guard let user = realm.user(id: userID) else {
                    throw RealmError.missingObject
                }
                /// Update following status.
                user.following = true
                
                /// Bring user timeline up to speed (Part 1).
                user.timelineWindow = .new()
            }
        } catch {
            ModelLog.error("Failed to update storage after follow! Error: \(error)")
            assert(false)
        }
    }
    
    /// Do `try-catch` memberwise, so that one `throw` does not prevent other `User`s being updated.
    for userID in userIDs {
        onFollow(userID: userID)
    }
    
    /// Bring user timeline up to speed (Part 2 – Fin).
    /// Don't block the UI for this background task.
    Task {
        await fetchTimelines()
    }
}
