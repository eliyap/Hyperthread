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
    
    public let author: User
    
    init(_ tweet: Tweet, depth: Int, parent: Node?, user: User) {
        self.tweet = tweet
        self.depth = depth
        self.children = []
        self.parent = parent
        self.author = user
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
    /// Returns the root node of a discussion tree data structure.
    func makeTree(airport: Airport) -> Node {
        let realm = try! Realm()
        
        /// Initialize the root node.
        let rootTweet = realm.tweet(id: self.id)!
        let root = Node(rootTweet, depth: 0, parent: nil, user: realm.user(id: rootTweet.authorID)!)
        
        /// Track nodes in the tree so far.
        var nodes = [root]
        
        /** Iterate over tweets chronologically.
            If a tweet "references" another tweet (quoting it, retweeting it, or replying to it),
            the referenced tweet *must* be older (otherwise that would violate causality!).
         
            By iterating chronologically, we guarantee each node *will* find its parent somewhere on the tree.
         
            Ignore the first node, which is the root, and is already in the tree with no parent.
         */
        let chron = self.tweets.sorted(by: Tweet.chronologicalSort)
        for t: Tweet in chron[1...] {
            /// Discard retweets.
            guard t.retweeting == nil else { continue }
            
            /// Safety checks.
            guard let PRID = t.primaryReference else {
                ModelLog.warning("""
                    Could not find primary reference ID while building tree.
                    - text: \(t.text)
                    - id: \(t.id)
                    """)
                assert(false)
                continue
            }
            guard let PRNode = nodes.first(where: {$0.tweet.id == PRID}) else {
                ModelLog.error("""
                    Could not find primary reference.
                    - PR-id \(PRID)
                    - Tweet: \(t)
                    """)
                if realm.tweet(id: PRID) != nil {
                    ModelLog.error("Primary Reference was present but not attached! id \(PRID)")
                }

                Task { await ReferenceCrawler.shared.fetchSingle(id: PRID) }
                assert(false)
                
                continue
            }
            let newNode = Node(t, depth: PRNode.depth + 1, parent: PRNode, user: realm.user(id: t.authorID)!)
            nodes.append(newNode)
        }
        return root
    }
}

extension Node {
    /// When there is a chain of replies, by Twitter convention, the users in the chain are @mentioned at the start of the tweet's text.
    /// Find and return the user handles upstream (in the reply chain) from this node, if any.
    func getReplyHandles() -> Set<String> {
        var result: Set<String> = []
        
        var curr: Node? = self
        
        /// Check that parent exists and that this tweet is a reply to the parent.
        /// - Note: exclude the current tweet, otherwise all leading @mentions would be omitted.
        while
            let c = curr,
            c.tweet.isReply,
            let p = c.parent,
            c.tweet.replying_to == p.id
        {
            /// Include the author and any accounts they @mention.
            result.insert(p.author.handle)
            if let handles = p.tweet.entities?.mentions.map(\.handle) {
                for handle in handles {
                    result.insert(handle)
                }
            }
            
            ///  Advance upwards.
            curr = p
        }
        
        return result
    }
}
