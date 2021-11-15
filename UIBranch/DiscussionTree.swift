//
//  DiscussionTree.swift
//  
//
//  Created by Secret Asian Man Dev on 14/11/21.
//

import Foundation
import RealmSwift

final class Node {
    public let tweet: Tweet
    
    /// How many references away `tweet` is from the discussion root.
    public let depth: Int
    
    /// - Note: nodes must be chronologically sorted by `createdAt`.
    private(set) var referencing: [Node]
    
    init(_ tweet: Tweet, depth: Int) {
        self.tweet = tweet
        self.depth = depth
        self.referencing = []
    }
    
    /// Use tail recursion to create proper list.
    func assemble(_ array: inout [Tweet]) -> Void {
        array.append(tweet)
        for node in referencing {
            node.assemble(&array)
        }
    }
    
    func append(_ node: Node) -> Void {
        referencing.append(node)
    }
}

extension Discussion {
    func makeTree() -> Node {
        let realm = try! Realm()
        let root = Node(realm.tweet(id: self.id)!, depth: 0)
        let chron = self.tweets.sorted { $0.createdAt < $1.createdAt }
        var nodes = [root]
        
        
        for t: Tweet in chron[1...] {
            guard let PRID = t.primaryReference else {
                assert(false, "No primary reference.")
                continue
            }
            guard let PRNode = nodes.first(where: {$0.tweet.id == PRID}) else {
                assert(false, "Could not find primary reference.")
                continue
            }
            let newNode = Node(t, depth: PRNode.depth + 1)
            PRNode.append(newNode)
            nodes.append(newNode)
        }
//        /// Assign depths to all tweets.
//        for t: Tweet in chron {
//            guard t.depth == nil else { continue }
//            guard t.id != self.id else { t.depth = 0; continue }
//
//            guard let PRID = t.primaryReference else {
//                assert(false, "No primary reference.")
//                continue
//            }
//            guard let PR = chron.first(where: {$0.id == PRID}) else {
//                assert(false, "Could not find primary reference.")
//                continue
//            }
//            guard let PRDepth = PR.depth else {
//                assert(false, "Primary Reference has no depth.")
//                continue
//            }
//            t.depth = PRDepth + 1
//        }
        return root
    }
}
