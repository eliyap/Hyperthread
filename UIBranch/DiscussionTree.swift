//
//  DiscussionTree.swift
//  
//
//  Created by Secret Asian Man Dev on 14/11/21.
//

import Foundation
import RealmSwift

final class Node: Identifiable {
    public var id: Tweet.ID { tweet.id }
    
    public let tweet: Tweet
    
    /// How many references away `tweet` is from the discussion root.
    public let depth: Int
    
    public private(set) weak var parent: Node!
    
    /// - Note: nodes must be chronologically sorted by `createdAt`.
    public private(set) var children: [Node]
    
    init(_ tweet: Tweet, depth: Int, parent: Node?) {
        self.tweet = tweet
        self.depth = depth
        self.children = []
        self.parent = parent
        parent?.append(self)
    }
    
    /// Use tail recursion to create proper list.
    func assemble(_ array: inout [Node]) -> Void {
        array.append(self)
        for node in children {
            node.assemble(&array)
        }
    }
    
    private func append(_ node: Node) -> Void {
        children.append(node)
    }
}

extension Node: Equatable {
    static func == (lhs: Node, rhs: Node) -> Bool {
        return lhs.tweet == rhs.tweet && lhs.depth == rhs.depth && lhs.children == rhs.children
    }
}
extension Node: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(tweet)
        hasher.combine(depth)
        hasher.combine(children)
    }
}

extension Discussion {
    func makeTree() -> Node {
        let realm = try! Realm()
        let root = Node(realm.tweet(id: self.id)!, depth: 0, parent: nil)
        let chron = self.tweets.sorted { $0.createdAt < $1.createdAt }
        var nodes = [root]
        
        
        for t: Tweet in chron[1...] {
            /// Discard retweets.
            guard t.retweeting == nil else { continue }
            
            /// Safety checks.
            guard let PRID = t.primaryReference else {
                assert(false, "No primary reference.")
                continue
            }
            guard let PRNode = nodes.first(where: {$0.tweet.id == PRID}) else {
                assert(false, "Could not find primary reference.")
                continue
            }
            let newNode = Node(t, depth: PRNode.depth + 1, parent: PRNode)
            nodes.append(newNode)
        }
        return root
    }
}
