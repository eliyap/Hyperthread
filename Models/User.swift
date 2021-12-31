//
//  User.swift
//  BranchRealm
//
//  Created by Secret Asian Man Dev on 31/10/21.
//

import Foundation
import RealmSwift
import Realm
import Twig

final class User: Object, Identifiable, UserIdentifiable {
    
    @Persisted(primaryKey: true) 
    var id: ID
    typealias ID = String
    
    /// User's Twitter handle.
    @Persisted 
    var name: String
    
    /// User's displayed name.
    @Persisted 
    var handle: String
    
    /// Whether our user follows this Twitter user.
    /// - Note: not included in `RawUser` object, hence we default initialize it.
    @Persisted
    var following: FollowingPropertyType
    static let followingPropertyName = "following"
    public typealias FollowingPropertyType = Bool
    
    /// The date window fetched for this user.
    @Persisted
    private var _timelineWindow: RealmDateWindow! = .init(.new())
    public var timelineWindow: DateWindow {
        get { .init(_timelineWindow) }
        set { _timelineWindow = .init(newValue) }
    }
    
    init(raw: RawUser, following: Bool) {
        super.init()
        self.id = "\(raw.id)"
        self.name = raw.name
        self.handle = raw.screen_name
        self.following = following
    }
    
    init(raw: RawIncludeUser, following: Bool) {
        super.init()
        self.id = raw.id
        self.name = raw.name
        self.handle = raw.username
        self.following = following
    }
    
    override required init() {
        super.init()
    }
}

public extension Int64 {
    static let NSNotFound = Int64(Foundation.NSNotFound)
}

internal extension Realm {
    func storeFollowing(raw: [RawIncludeUser]) throws -> Void {
        try write {
            /// Remove users who are no longer being followed.
            followingUsers()
                .filter { user in
                    /// Find users who were marked as followed but are now missing.
                    raw.contains(where: {user.id == $0.id}) == false
                }
                .forEach { user in
                    user.following = false
                }
            
            /// Write out users to account for possible new users.
            raw.forEach {
                let user = User(raw: $0, following: true)
                add(user, update: .all)
            }
        }
    }
}
