//
//  Relevance.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 16/12/21.
//

import Foundation
import RealmSwift
import Twig

internal enum Relevance: Int {
    /// As-yet-unused.
    /// Indicates blocked, filtered, or muffled content.
    case blocked = -1
    
    /// Indicates content that should not be surfaced except as context,
    /// e.g. it is upstream of a more relevant Tweet.
    case irrelevant = 0
    
    /// Indicates content that should be included in the Discussion's "comment section",
    /// but does not itself cause the discussion to surface.
    case reply = 500
    
    /// Indicates an external tweet (not from any timeline)
    /// which the user would like to look up.
    case lookup = 950
    
    /// Indicates content that "surfaces" a `Discussion`,
    /// i.e. this Tweet is why you see this `Discussion`.
    case discussion = 999
    
    init(
        tweet: AuthorIdentifiable & ReplyIdentifiable & RetweetIdentifiable,
        following userIDs: [User.ID]
    ) {
        /// If the user is not followed, it is irrelevant (for now).
        /// - Note: in future, we may wish to include say, the originator of the discussion.
        guard userIDs.contains(where: { $0 == tweet.authorID }) else {
            self = .irrelevant
            return
        }
        
        if tweet.replyID != nil || tweet.retweetID != nil {
            self = .reply
            return
        } else {
            self = .discussion
            return
        }
    }
    
    /// Minimum relevance to be considered worth fetching.
    public static let fetchThreshold = lookup.rawValue
    
    /// Minimum relevance to be considered worth fetching.
    public static let displayThreshold = discussion.rawValue
}
