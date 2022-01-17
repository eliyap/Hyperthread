//
//  StoreFollowing.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 17/1/22.
//

import Foundation
import RealmSwift
import Twig

internal extension Realm {
    /// Write following users to disk.
    func storeFollowing<RawUserCollection>(raw: RawUserCollection) throws -> Void
    where
        RawUserCollection: Collection,
        RawUserCollection.Element == RawUser
    {
        try write {
            /// Remove users who are no longer being followed.
            objects(User.self)
                .where { $0.following == true }
                .filter { user in
                    /// Find users who were marked as followed but are now missing.
                    raw.contains(where: {user.id == $0.id}) == false
                }
                .forEach { user in
                    #warning("TODO: perform unfollow actions!")
                    user.following = false
                }
            
            /// Write out users to account for possible new users.
            raw.forEach {
                #warning("TODO: perform follow actions!")
                let user = User(raw: $0, following: true)
                add(user, update: .all)
            }
        }
    }
}
