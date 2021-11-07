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

final class User: Object, Identifiable {
    
    @Persisted(primaryKey: true) 
    var id: ID
    typealias ID = String
    
    /// User's Twitter handle.
    @Persisted 
    var name: String
    
    /// User's displayed name.
    @Persisted 
    var screen_name: String
    
    @Persisted 
    var tweets: RealmSwift.List<Tweet>
    static let tweetsPropertyName = "tweets"
    
    init(raw: RawUser) {
        super.init()
        self.id = "\(raw.id)"
        self.name = raw.name
        self.screen_name = raw.screen_name
        self.tweets = RealmSwift.List<Tweet>()
    }
    
    init(raw: RawIncludeUser) {
        super.init()
        self.id = raw.id
        self.name = raw.name
        self.screen_name = raw.username
        self.tweets = RealmSwift.List<Tweet>()
    }
    
    override required init() {
        super.init()
    }
}

public extension Int64 {
    static let NSNotFound = Int64(Foundation.NSNotFound)
}


extension User {
    public func insert(_ tweet: Tweet) {
        if tweets.contains(where: {$0.id == tweet.id}) == false {
            tweets.append(tweet)
        }
    }
}
