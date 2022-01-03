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
         
        var removedURLs: [String] = []
        
        if let node = node {
            /// The user @handles in the reply chain.
            let replyHandles: Set<String> = node.getReplyHandles()
            
            /** Remove replying @mentions. */
            text.removeReplyAtMentions(in: self, replyHandles: replyHandles)
        }
        
        /// Replace `t.co` links with truncated links.
        text.expandURLs(from: self, removedURLs: &removedURLs)
        
        /// Apply normal text size and color preferences.
        let string = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.label,
        ])
        
        /// Track link-attributed ranges to avoid overlaps.
        var linkedRanges: [NSRange] = []
        
        /// Hyperlink substituted links.
        string.addHyperlinks(from: self, removedURLs: removedURLs, linkedRanges: &linkedRanges)
        
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
            /// Use `lowercased` for case-insensitive matching, due to Twitter matches @-handles case-insensitively.
            guard self[cursor..<endIndex].lowercased().starts(with: atHandle.lowercased()) else {
                if lowercased().contains(atHandle.lowercased()) == false {
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
    mutating func expandURLs(from tweet: Tweet, removedURLs: inout [String]) -> Void {
        guard let urls = tweet.entities?.urls else { return }
        
        for url in urls {
            guard let target = range(of: url.url) else {
                Swift.debugPrint("Could not find url \(url.url) in \(self)")
                Swift.debugPrint("URLs: ", urls.map(\.url))
                continue
            }
            
            if
                /// By convention(?), quote tweets have the quoted URL at the end.
                /// If URL references the quote, we can safely remove it, IF it is not also a reply.
                tweet.quoting != nil,
                tweet.quoting == tweet.primaryReference,
                target.upperBound == endIndex,
                url.display_url.starts(with: "twitter.com/")
            {
                /// Set variable so we know not to look for this URL in the future.
                removedURLs.append(url.display_url)
                replaceSubrange(target, with: "")
            } else if
                /// If the tweet has media, and this looks like a media link, omit the URL.
                tweet.media.isNotEmpty,
                url.display_url.starts(with: "pic.twitter.com/")
            {
                /// Set variable so we know not to look for this URL in the future.
                removedURLs.append(url.display_url)
                replaceSubrange(target, with: "")
            } else  {
                replaceSubrange(target, with: url.display_url)
            }
        }
    }
}

extension NSMutableAttributedString {
    
    /// Hyperlink substituted links.
    /// - Parameters:
    ///   - quotedDisplayURL: optional, for debugging. The URL of the quoted tweet (if any), which is appended to the tweet text by convention.
    func addHyperlinks(from tweet: Tweet, removedURLs: [String], linkedRanges: inout [NSRange]) -> Void {
        guard let urls = tweet.entities?.urls else { return }
        
        /**
         Iterate from beginning to end, taking care to attach a new link _after_ the previous link.
         `lastTarget` tracks the previous URL range.
         
         This helps us avoid attaching a link to the same range twice,
         e.g. in the Tweet "How long has google.com owned the domain google.com?"
         
         Observed this edge case here: https://twitter.com/apollographql/status/1469067842658185226
         */
        var lastTarget: Range<String.Index> = string.startIndex..<string.startIndex
        let sorted = urls.sorted(by: {$0.start < $1.start})
        for url in sorted {
            /// Obtain URL substring range.
            /// - Note: Should never fail! We just put this URL in!
            guard let target = string.range(of: url.display_url, range: lastTarget.upperBound..<string.endIndex) else {
                if removedURLs.contains(url.display_url) {
                    /** Ignore URLs which were registered as removed.. **/
                } else {
                    ModelLog.warning("Could not find display_url \(url.display_url) in \(string)")
                }
                continue
            }
            lastTarget = target
            
            /// Transform substring range to `NSRange` boundaries.
            guard let intRange = nsRange(target) else {
                ModelLog.warning("Could not cast offsets")
                continue
            }
            linkedRanges.append(intRange)
            
            /// As of November 2021, Twitter truncated URLs. They *may* have changed this.
            if url.expanded_url.contains("…") {
                ModelLog.warning("Truncted URL \(url.expanded_url)")
                
                /// Fall back to the `t.co` link.
                addAttribute(.link, value: url.url, range: intRange)
            } else {
                addAttribute(.link, value: url.expanded_url, range: intRange)
            }
        }
        
        let sortedMentions: [Mention] = tweet.entities?.mentions.sorted(by: {$0.start < $1.start}) ?? []
        for mention in sortedMentions {
            let atHandle = "@" + mention.handle
            
            /// Perform case insensitive search, just as Twitter does.
            guard let target = string.range(of: atHandle, options: .caseInsensitive) else {
                /// It's normal to fail to find @mentions, since many are removed from the string.
                continue
            }
            
            /// Transform substring range to `NSRange` boundaries.
            guard let intRange = nsRange(target) else {
                ModelLog.warning("Could not cast offsets")
                continue
            }

            /// Check for overlapping links, which should never happen.
            guard linkedRanges.allSatisfy({NSIntersectionRange($0, intRange).length == .zero}) else {
                ModelLog.warning("""
                    Found intsersection of @mention and url!
                    - ranges \(linkedRanges)
                    - handle \(atHandle)
                    - text \(tweet.text)
                    """)
                continue
            }
            linkedRanges.append(intRange)
            
            addAttribute(.link, value: "handle://\(mention.id)", range: intRange)
        }
    }
    
    /// Transform substring range to `NSRange` boundaries.
    fileprivate func nsRange(_ strRange: Range<String.Index>) -> NSRange? {
        guard
            let low16 = strRange.lowerBound.samePosition(in: string.utf16),
            let upp16 = strRange.upperBound.samePosition(in: string.utf16)
        else {
            return nil
        }
        let lowInt = string.utf16.distance(from: string.utf16.startIndex, to: low16)
        let uppInt = string.utf16.distance(from: string.utf16.startIndex, to: upp16)
        
        return NSMakeRange(lowInt, uppInt-lowInt)
    }
}
