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
    
    /// User's text profile description (aka bio), if any.
    @Persisted
    var bio: String
    
    @Persisted
    var pinnedTweetID: Tweet.ID?
    
    @Persisted
    var profileImageUrl: String?
    
    /// Whether `User`'s tweets are protected (aka private).
    @Persisted
    var protected: Bool
    
    /// UTC datetime that `User` account was created on Twitter.
    @Persisted
    var createdAt: Date

    /// Whether our user follows this Twitter user.
    /// - Note: not included in `RawUser` object.
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
        self.id = raw.id
        self.name = raw.name
        self.handle = raw.username
        self.bio = raw.description
        #warning("TODO: bio entities")
        self.pinnedTweetID = raw.pinned_tweet_id
        self.profileImageUrl = raw.profile_image_url
        self.protected = raw.protected
        self.createdAt = raw.created_at
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
    func storeFollowing(raw: [RawUser]) throws -> Void {
        try write {
            /// Remove users who are no longer being followed.
            followingUsers()
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

extension User {
    var resolvedProfileImageUrl: URL? {
        guard let str = profileImageUrl else { return nil }
        
        /// Attempt to get full resolution image.
        /// Source: https://stackoverflow.com/questions/50190620/getting-bigger-resolution-profile-image-from-twitter-api
        let originalStr = str.replacingOccurrences(of: "_normal.", with: ".")
        if
            let url = URL(string: originalStr),
            UIApplication.shared.canOpenURL(url)
        {
            return url
        } else if
            /// Fall back to provided string.
            let url = URL(string: str),
            UIApplication.shared.canOpenURL(url)
        {
            return url
        } else {
            return nil
        }
    }
}
