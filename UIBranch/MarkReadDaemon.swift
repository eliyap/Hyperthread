//
//  MarkReadDaemon.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 21/11/21.
//

import RealmSwift

/**
 - Note: cannot be an `Actor`, otherwise `Realm` crashes.
 */
final class MarkReadDaemon {
    
    let token: NotificationToken
    
    public init(token: NotificationToken) {
        self.token = token
    }
    
    private let realm = try! Realm()
    
    /// `seen` indicates whether the discussion was fully visible for the user to read.
    var indices: [IndexPath: Discussion] = [:]
    
    func associate(_ path: IndexPath, with discussion: Discussion) {
        indices[path] = discussion
    }
    
    /// Marks the index path as having been seen.
    func mark(_ path: IndexPath) {
        guard let discussion: Discussion = indices[path] else {
            Swift.debugPrint("Missing key \(path)")
            return
        }
        if discussion.tweetCount == 1 {
            do {
                try realm.write(withoutNotifying: [token]) {
                    discussion.read = .read
                }
            } catch {
                // TODO: log non-critical failure.
                assert(false, "\(error)")
                return
            }
        }
    }
}
