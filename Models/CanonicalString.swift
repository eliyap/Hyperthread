//
//  CanonicalString.swift
//  
//
//  Created by Secret Asian Man Dev on 23/11/21.
//

import Foundation
import Twig
import UIKit

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
            /// The user @handles in the reply chain.
            let replyHandles: Set<String> = node.getReplyHandles()
            
            /** Remove replying @mentions. */
            text.removeReplyAtMentions(in: self, replyHandles: replyHandles)
        }
        
        /// Replace `t.co` links with truncated links.
        text.expandURLs(from: self, quotedDisplayURL: &quotedDisplayURL)
        
        /// Apply normal text size and color preferences.
        let string = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.label,
        ])
        
        /// Hyperlink substituted links.
        string.addHyperlinks(from: self, quotedDisplayURL: quotedDisplayURL)
        
        return string
    }
}

extension String {
    
    /** Remove replying @mentions. */
    mutating func removeReplyAtMentions(in tweet: Tweet, replyHandles: Set<String>) -> Void {
        guard let mentions = tweet.entities?.mentions else { return }
        
        let sortedMentions = mentions.sorted(by: {$0.start < $1.start})
        var cursor: String.Index = startIndex
        
        /// Look for @mentions in the order they appear, advancing `cursor` to the end of each mention.
        for mention in sortedMentions {
            let atHandle = "@" + mention.handle
            
            /// Ensure @mention is right after the `cursor`.
            guard self[cursor..<endIndex].starts(with: atHandle) else {
                if contains(atHandle) == false {
                    ModelLog.warning("Mention \(atHandle) not found in \(self)")
                }
                break
            }
            
            guard replyHandles.contains(mention.handle) else {
                ModelLog.warning("Mention \(atHandle) not found in \(replyHandles)")
                break
            }
            let range = range(of: atHandle + " ") ?? range(of: atHandle)!
            cursor = range.upperBound
        }
        
        /// Erase everything before cursor.
        removeSubrange(startIndex..<cursor)
    }
    
    /// Replace `t.co` links with truncated links.
    mutating func expandURLs(from tweet: Tweet, quotedDisplayURL: inout String?) -> Void {
        guard let urls = tweet.entities?.urls else { return }
        
        for url in urls {
            guard let target = range(of: url.url) else {
                Swift.debugPrint("Could not find url \(url.url) in \(self)")
                Swift.debugPrint("URLs: ", urls.map(\.url))
                continue
            }
            
            /// By convention(?), quote tweets have the quoted URL at the end.
            /// If URL references the quote, we can safely remove it, IF it is not also a reply.
            if
                tweet.quoting != nil,
                tweet.quoting == tweet.primaryReference,
                target.upperBound == endIndex,
                url.display_url.starts(with: "twitter.com/")
            {
                /// Set variable so we know not to look for this URL in the future.
                quotedDisplayURL = url.display_url
                replaceSubrange(target, with: "")
            } else {
                replaceSubrange(target, with: url.display_url)
            }
        }
    }
}

extension NSMutableAttributedString {
    
    /// Hyperlink substituted links.
    /// - Parameters:
    ///   - quotedDisplayURL: optional, for debugging. The URL of the quoted tweet (if any), which is appended to the tweet text by convention.
    func addHyperlinks(from tweet: Tweet, quotedDisplayURL: String? = nil) -> Void {
        guard let urls = tweet.entities?.urls else { return }
        
        for url in urls {
            /// Obtain URL substring range.
            /// - Note: Should never fail! We just put this URL in!
            guard let target = string.range(of: url.display_url) else {
                if quotedDisplayURL != nil && url.display_url == quotedDisplayURL {
                    /** ignore quote URL, which is intentionally omitted. **/
                } else {
                    ModelLog.warning("Could not find display_url \(url.display_url) in \(string)")
                }
                continue
            }
            
            /// Transform substring range to `NSRange` boundaries.
            guard
                let low16 = target.lowerBound.samePosition(in: string.utf16),
                let upp16 = target.upperBound.samePosition(in: string.utf16)
            else {
                ModelLog.warning("Could not cast offsets")
                continue
            }
            let lowInt = string.utf16.distance(from: string.utf16.startIndex, to: low16)
            let uppInt = string.utf16.distance(from: string.utf16.startIndex, to: upp16)
            
            /// As of November 2021, Twitter truncated URLs. They *may* have changed this.
            if url.expanded_url.contains("…") {
                ModelLog.warning("Truncted URL \(url.expanded_url)")
                
                /// Fall back to the `t.co` link.
                addAttribute(.link, value: url.url, range: NSMakeRange(lowInt, uppInt-lowInt))
            } else {
                addAttribute(.link, value: url.expanded_url, range: NSMakeRange(lowInt, uppInt-lowInt))
            }
        }
    }
}
