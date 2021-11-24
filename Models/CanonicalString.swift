//
//  CanonicalString.swift
//  
//
//  Created by Secret Asian Man Dev on 23/11/21.
//

import Foundation
import Twig

extension Tweet {
    /**
     Relies on properties:
     - `text`
     - `entities`
     */
    
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
