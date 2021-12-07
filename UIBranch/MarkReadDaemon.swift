//
//  MarkReadDaemon.swift
//  Hyperthread
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
    func mark(_ paths: [IndexPath]) -> Void {
        do {
            guard realm.isInWriteTransaction == false else {
                /// Observed some kind of recusrive call here, ignore it and simply skip the write.
                TableLog.error("Realm already in write transaction!")
                return
            }
            try realm.write(withoutNotifying: excludeTokens) {
                for path in paths {
                    guard let discussion: Discussion = indices[path] else {
                        TableLog.debug("Mark Daemon missing key \(path)")
                        continue
                    }
                    if discussion.tweetCount == 1 {
                        discussion.read = .read
                    }
                }
            }
        } catch {
            ModelLog.error("\(error)")
            return
        }
    }
}
