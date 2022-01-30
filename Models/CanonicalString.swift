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
    
    public static let textAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.preferredFont(forTextStyle: .body),
        .foregroundColor: UIColor.label,
    ]
    /// If `node` is provided, we can derive some additional context.
    func fullText(context node: Node? = nil) -> NSMutableAttributedString {
        /// Replace encoded characters.
        var text = text
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&amp;", with: "&")
         
        var removedURLs: [String] = []
        var removedHandles: Set<String> = []
        
        if let node = node {
            /// The user @handles in the reply chain.
            let replyHandles: Set<String> = node.getReplyHandles()
            
            /** Remove replying @mentions. */
            removedHandles = text.removeReplyAtMentions(in: self, replyHandles: replyHandles)
        }
        
        /// Replace `t.co` links with truncated links.
        text.expandURLs(from: self, removedURLs: &removedURLs)
        
        /// Apply normal text size and color preferences.
        let string = NSMutableAttributedString(string: text, attributes: Self.textAttributes)
        
        /// Track link-attributed ranges to avoid overlaps.
        var linkedRanges: [NSRange] = []
        
        /// Hyperlink substituted links.
        string.addHyperlinks(from: self, removedURLs: removedURLs, linkedRanges: &linkedRanges)
        string.linkAtMentions(tweet: self, linkedRanges: &linkedRanges, removedHandles: removedHandles)
        string.linkTags(tweet: self, linkedRanges: &linkedRanges)
        
        return string
    }
}

extension String {
    
    /** Remove replying @mentions. */
    @discardableResult
    mutating func removeReplyAtMentions(in tweet: Tweet, replyHandles: Set<String>) -> Set<String> {
        guard let mentions = tweet.entities?.mentions else { return [] }
        
        let sortedMentions = mentions.sorted(by: {$0.start < $1.start})
        var cursor: String.Index = startIndex
        var removedHandles: Set<String> = []
        
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
            removedHandles.insert(atHandle)
        }
        
        /// Erase everything before cursor.
        removeSubrange(startIndex..<cursor)
        
        return removedHandles
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
                /// If URL references the quote, we can safely remove it.
                tweet.quoting != nil,
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
    }
    
    /// - Parameters:
    ///   - removedHandles: the @handles that were already removed from the string, which we may skip over.
    func linkAtMentions(tweet: Tweet, linkedRanges: inout [NSRange], removedHandles: Set<String>) -> Void {
        
        /// Iterate over string in order of appearance.
        /// This helps distinguish `@Script` from `@ScriptoriumGirl` in "I follow @Script and @ScriptoriumGirl".
        /// Don't use trailing space, because of accepted case "@Script's tweets are the best!"
        let sortedMentions: [Mention] = tweet.entities?.mentions.sorted(by: {$0.start < $1.start}) ?? []
        var cursor = string.startIndex
        
        for mention in sortedMentions {
            let atHandle = "@" + mention.handle
            
            /// Perform case insensitive search, just as Twitter does.
            /// Search starting from `cursor`.
            guard let target = string.range(of: atHandle, options: .caseInsensitive, range: cursor..<string.endIndex) else {
                /// It's normal to fail to find @mentions if they were removed from the string.
                if removedHandles.contains(atHandle) == false {
                    ModelLog.warning("Could not find \(atHandle) in \(string)")
                }
                continue
            }
            cursor = target.upperBound
            
            /// Transform substring range to `NSRange` boundaries.
            guard let intRange = nsRange(target) else {
                ModelLog.warning("Could not cast offsets")
                continue
            }

            /// Check for overlapping links, which should never happen.
            guard linkedRanges.allSatisfy({NSIntersectionRange($0, intRange).length == .zero}) else {
                ModelLog.warning("""
                    Found intersection of @mention and existing ranges!
                    - ranges \(linkedRanges)
                    - intersecting range \(intRange)
                    - handle \(atHandle)
                    - text \(tweet.text)
                    """)
                continue
            }
            linkedRanges.append(intRange)
            
            addAttribute(.link, value: UserURL.urlString(mention: mention), range: intRange)
        }
    }
    
    func linkTags(tweet: Tweet, linkedRanges: inout [NSRange]) -> Void {
        /// Iterate over string in order of appearance.
        /// This helps distinguish `#swift` from `#swiftLang` in "I love #Swift #swiftLang".
        /// Don't use trailing spaces.
        let sortedTags: [Tag] = tweet.entities?.hashtags.sorted(by: {$0.start < $1.start}) ?? []
        var cursor = string.startIndex
        
        for tag in sortedTags {
            let hashtag = "#" + tag.tag
            
            /// Perform case insensitive search, just as Twitter does.
            guard let target = string.range(of: hashtag, options: .caseInsensitive, range: cursor..<string.endIndex) else {
                ModelLog.warning("Could not find \(hashtag) in \(string)")
                continue
            }
            cursor = target.upperBound
            
            /// Transform substring range to `NSRange` boundaries.
            guard let intRange = nsRange(target) else {
                ModelLog.warning("Could not cast offsets")
                continue
            }

            /// Check for overlapping links, which should never happen.
            guard linkedRanges.allSatisfy({NSIntersectionRange($0, intRange).length == .zero}) else {
                ModelLog.warning("""
                    Found intersection of #hashtag and existing ranges!
                    - ranges \(linkedRanges)
                    - intersecting range \(intRange)
                    - hashtag \(hashtag)
                    - text \(tweet.text)
                    - hashtag objects \(sortedTags)
                    """)
                continue
            }
            linkedRanges.append(intRange)
            
            addAttribute(.link, value: HashtagURL.urlString(tag: tag), range: intRange)
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
