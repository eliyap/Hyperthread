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
    var following: Bool = false
    static let followingPropertyName = "following"
    
    @Persisted
    private var _timelineWindow: RealmDateWindow = .init(.new())
    public var timelineWindow: DateWindow {
        get { .init(_timelineWindow) }
        set { _timelineWindow = .init(newValue) }
    }
    
    init(raw: RawUser) {
        super.init()
        self.id = "\(raw.id)"
        self.name = raw.name
        self.handle = raw.screen_name
    }
    
    init(raw: RawIncludeUser) {
        super.init()
        self.id = raw.id
        self.name = raw.name
        self.handle = raw.username
    }
    
    override required init() {
        super.init()
    }
}

public extension Int64 {
    static let NSNotFound = Int64(Foundation.NSNotFound)
}
