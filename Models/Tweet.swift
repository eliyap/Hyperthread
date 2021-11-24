//
//  Tweet.swift
//  BranchRealm
//
//  Created by Secret Asian Man Dev on 29/10/21.
//

import Foundation
import RealmSwift
import Realm
import Twig

final class PublicMetrics: EmbeddedObject {
    
    @Persisted 
    var like_count: Int
    
    @Persisted 
    var retweet_count: Int

    @Persisted
    var reply_count: Int

    @Persisted
    var quote_count: Int
    
    override required init() {
    }
    
    init(raw: RawPublicMetrics) {
        like_count = raw.like_count
        retweet_count = raw.retweet_count
        reply_count = raw.reply_count
        quote_count = raw.quote_count    
    }
}

final class Tweet: Object, Identifiable {
    
    /// Twitter API `id`.
    @Persisted(primaryKey: true) 
    var id: ID
    typealias ID = String
    
    @Persisted
    var createdAt: Date
    
    /// Tweet's body text.
    @Persisted 
    var text: String
    
    /// - Note: Realm requires embedded objects to be optional.
    @Persisted
    var metrics: PublicMetrics!
    
    /// - Note: `LinkingObjects` failed me, so use an ID instead.
    /// Fortunately, we can assume that a Tweet will never change users.
    @Persisted
    var authorID: User.ID
    
    /// - Note: Tweet must belong to a unique ``Conversation``.
    @Persisted(originProperty: Conversation.tweetsPropertyName)
    var conversation: LinkingObjects<Conversation>
    public static let conversationPropertyName = "conversation"
    
    /// The ID whose `Conversation` this Tweet belongs to.
    /// Note this is also the ID of the Conversation's root tweet.
    @Persisted
    var conversation_id: ID
    
    @Persisted
    var replying_to: ID?
    
    @Persisted
    var retweeting: ID?
    
    @Persisted
    var quoting: ID?
    
    /// - Note: Realm requires embedded objects to be optional.
    @Persisted
    var entities: Entities?
    
    /// Whether the user has read this tweet.
    @Persisted
    var read: Bool
    
    @Persisted
    var media: List<Media>
    
    init(raw: RawHydratedTweet, rawMedia: [RawIncludeMedia]) {
        super.init()
        self.id = raw.id
        self.createdAt = raw.created_at
        self.text = raw.text
        self.conversation_id = raw.conversation_id
        self.metrics = PublicMetrics(raw: raw.public_metrics)
        self.authorID = raw.author_id
        self.read = false
        
        if let references = raw.referenced_tweets {
            for reference in references {
                switch reference.type {
                case .replied_to:
                    replying_to = reference.id
                case .quoted:
                    quoting = reference.id
                case .retweeted:
                    retweeting = reference.id
                }
            }
        }
        
        if let rawEntities = raw.entities {
            entities = Entities(raw: rawEntities)
        } else {
            entities = nil
        }
        
        media = List<Media>()
        if let keys = raw.attachments?.media_keys {
            for key in Set(keys) {
                guard let match = rawMedia.first(where: {$0.media_key == key}) else {
                    Swift.debugPrint("Failed to find match for \(key)")
                    continue
                }
                media.append(Media(raw: match))
            }
        }
    }
    
    override required init() {
        super.init()
    }
}

extension Tweet {
    /// The tweet we consider this tweet to be primarily "pointing to".
    /// Resolves in (personally preferred) order of precedence.
    var primaryReference: ID? {
        replying_to ?? quoting ?? retweeting
    }
    
    var primaryReferenceType: RawReferenceType? {
        if replying_to != nil { return .replied_to }
        if quoting != nil { return .quoted }
        if retweeting != nil { return .retweeted }
        return .none
    }
}

// MARK: - Convenience Methods.
extension Tweet {
    var referenced: [ID] {
        [
            replying_to,
            retweeting,
            quoting
        ].compactMap { $0 }
    }
}

extension Tweet.ID {
    func missingFrom(_ realm: Realm) -> Bool {
        realm.tweet(id: self) == nil
    }
}

extension Array where Element == Tweet.ID {
    func missingFrom(_ realm: Realm) -> Self {
        filter { $0.missingFrom(realm) }
    }
}

extension Tweet {
    var isRetweet: Bool { retweeting != nil }
    var isQuote: Bool { quoting != nil }
    var isReply: Bool { replying_to != nil }
}

extension Tweet {
    /// If `node` is provided, we can derive some additional context.
    func fullText(context node: Node? = nil) -> NSMutableAttributedString {
        /// Replace encoded characters.
        var text = text
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&amp;", with: "&")
         
        var quotedDisplayURL: String? = nil
        
        if let node = node {
            /// Compile UserIDs in a reply chain.
            var replyHandles: Set<String> = []
            var curr: Node? = node
            while let c = curr {
                /// Include the author and any accounts they @mention.
                replyHandles.insert(c.author.handle)
                if let handles = c.tweet.entities?.mentions.map(\.handle) {
                    for handle in handles {
                        replyHandles.insert(handle)
                    }
                }
                
                /// Move upwards only if tweet was replying.
                guard
                    c.tweet.replying_to != nil,
                    c.tweet.replying_to == c.parent?.id
                else { break }
                curr = c.parent
            }
            
            /** Remove replying @mentions.
                Look for @mentions in the order they appear, advancing `cursor`
                to the end of each mention.
                Then, erase everything before cursor.
             */
            if let mentions = entities?.mentions {
                let mentions = mentions.sorted(by: {$0.start < $1.start})
                var cursor: String.Index = text.startIndex
                for mention in mentions {
                    let atHandle = "@" + mention.handle
                    
                    /// Ensure @mention is right after the `cursor`.
                    guard text[cursor..<text.endIndex].starts(with: atHandle) else {
                        if text.contains(atHandle) == false {
                            ModelLog.warning("Mention \(atHandle) not found in \(text)")
                        }
                        break
                    }
                    
                    guard replyHandles.contains(mention.handle) else {
                        ModelLog.warning("Mention \(atHandle) not found in \(replyHandles)")
                        break
                    }
                    let range = text.range(of: atHandle + " ") ?? text.range(of: atHandle)!
                    cursor = range.upperBound
                }
                text.removeSubrange(text.startIndex..<cursor)
            }
        }
        
        /// Replace `t.co` links with truncated links.
        if let urls = entities?.urls {
            for url in urls {
                guard let target = text.range(of: url.url) else {
                    Swift.debugPrint("Could not find url \(url.url) in \(text)")
                    Swift.debugPrint("URLs: ", urls.map(\.url))
                    continue
                }
                
                /// By convention(?), quote tweets have the quoted URL at the end.
                /// Definitely a quote, can safely remove it, IF it is not also a reply.
                if
                    quoting != nil,
                    quoting == primaryReference,
                    target.upperBound == text.endIndex,
                    url.display_url.starts(with: "twitter.com/")
                {
                    quotedDisplayURL = url.display_url
                    text.replaceSubrange(target, with: "")
                } else {
                    text.replaceSubrange(target, with: url.display_url)
                }
            }
        }
        
        /// Apply normal text size and color preferences.
        let string = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.label,
        ])
        
        /// Hyperlink substituted links.
        if let urls = entities?.urls {
            for url in urls {
                /// - Note: Should never fail! We just put this URL in!
                guard let target = text.range(of: url.display_url) else {
                    if url.display_url != quotedDisplayURL {
                        Swift.debugPrint("Could not find display_url \(url.display_url) in \(text)")
                    }
                    continue
                }
                guard
                    let low16 = target.lowerBound.samePosition(in: text.utf16),
                    let upp16 = target.upperBound.samePosition(in: text.utf16)
                else {
                    Swift.debugPrint("Could not cast offsets")
                    continue
                }
                let lowInt = text.utf16.distance(from: text.utf16.startIndex, to: low16)
                let uppInt = text.utf16.distance(from: text.utf16.startIndex, to: upp16)
                
                /// As of November 2021, Twitter truncated URLs.
                /// They may have changed this, I'm not sure.
                if url.expanded_url.contains("…") {
                    Swift.debugPrint("Truncted URL \(url.expanded_url)")
                    string.addAttribute(.link, value: url.url, range: NSMakeRange(lowInt, uppInt-lowInt))
                } else {
                    string.addAttribute(.link, value: url.expanded_url, range: NSMakeRange(lowInt, uppInt-lowInt))
                }
            }
        }
        
        return string
    }
}
