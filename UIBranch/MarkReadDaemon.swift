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
    
    /// Do not notify the `DiffableDataSource`, as it causes a `modification` bump, which causes an animation glitch (observed 21.11.23).
    let excludeTokens: [NotificationToken]
    
    public init(token: NotificationToken) {
        self.excludeTokens = [token]
    }
    
    private let realm = try! Realm()
    
    /// `seen` indicates whether the discussion was fully visible for the user to read.
    var indices: [IndexPath: Discussion] = [:]
    
    func associate(_ path: IndexPath, with discussion: Discussion) {
        indices[path] = discussion
    }
    
    /// Mark the discussion at this index path as `read`.
    func mark(_ path: IndexPath) {
        guard let discussion: Discussion = indices[path] else {
            Swift.debugPrint("Missing key \(path)")
            return
        }
        if discussion.tweetCount == 1 {
            do {
                try realm.write(withoutNotifying: excludeTokens) {
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
