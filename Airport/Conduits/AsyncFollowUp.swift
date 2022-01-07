//
//  AsyncFollowUp.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 7/1/22.
//

import Foundation
import RealmSwift

actor ReferenceCrawler {
    
    /// Singleton
    public static let shared: ReferenceCrawler = .init()
    private init() {}
    
    /// IDs of `Tweet`s that are already being fetched. Prevents duplication of effort.
    private var inFlight: Set<Tweet.ID> = []
    
    public func performFollowUp() -> Void {
        var dangling: Set<Tweet.ID> = []
        var convDangling: Set<Tweet.ID> = []
        var discDangling: Set<Tweet.ID> = []
        
        repeat {
            convDangling = getConversationDangling()
            discDangling = getDiscussionDangling()
            dangling = convDangling.union(discDangling)
            
        } while convDangling.isNotEmpty
    }
    
    /// Find dangling references in local database.
    fileprivate func getDangling() -> Set<Tweet.ID> {
        let realm = try! Realm()
        var toFetch: Set<Tweet.ID> = []
        
        let c = realm.conversationsWithFollowUp()
        toFetch.formUnion(c
            .map { $0.getFollowUp() }
            .reduce(Set<Tweet.ID>()) { $0.union($1) }
        )
        
        let d = realm.discussionsWithFollowUp()
        toFetch.formUnion(d
            .map { $0.getFollowUp() }
            .reduce(Set<Tweet.ID>()) { $0.union($1) }
        )
        
        NetLog.debug("\(c.count) conversations, \(d.count) discussions requiring follow up.", print: true, true)
        return toFetch
    }
}

/// Find dangling references in local database.
fileprivate func getConversationDangling() -> Set<Tweet.ID> {
    let realm = try! Realm()
    let toFetch: Set<Tweet.ID> = realm.conversationsWithFollowUp()
        .map { $0.getFollowUp() }
        .reduce(Set<Tweet.ID>()) { $0.union($1) }
    
    NetLog.debug("\(toFetch.count) conversation tweets requiring follow up.", print: true, true)
    return toFetch
}

fileprivate func getDiscussionDangling() -> Set<Tweet.ID> {
    let realm = try! Realm()
    let toFetch: Set<Tweet.ID> = realm.discussionsWithFollowUp()
        .map { $0.getFollowUp() }
        .reduce(Set<Tweet.ID>()) { $0.union($1) }
    
    NetLog.debug("\(toFetch.count) discussion tweets requiring follow up.", print: true, true)
    return toFetch
}
