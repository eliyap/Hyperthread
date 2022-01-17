//
//  Tweet.chronologicalSort.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 17/1/22.
//

import Foundation

extension Tweet {
    /// Sort Tweets chronologically.
    /// - Note: this is difficult because the `createdAt` timestamp has one-second resolution.
    static let chronologicalSort = { (lhs: Tweet, rhs: Tweet) -> Bool in
        /// Tie break by ID.
        /// I have observed tied timestamps. (see https://twitter.com/ChristianSelig/status/1469028219441623049)
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        } else {
            return lhs.id < rhs.id
        }
    }
}
