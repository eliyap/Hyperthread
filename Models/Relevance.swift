//
//  Relevance.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 16/12/21.
//

import Foundation
import RealmSwift

internal enum Relevance: Int, RealmEnum {
    /// As-yet-unused.
    /// Indicates blocked, filtered, or muffled content.
    case blocked = -1
    
    /// Indicates content that should not be surfaced except as context,
    /// e.g. it is upstream of a more relevant Tweet.
    case irrelevant = 0
    
    /// Indicates content that should be included in the Discussion's "comment section",
    /// but does not itself cause the discussion to surface.
    case reply = 500
    
    /// Indicates content that "surfaces" a `Discussion`,
    /// i.e. this Tweet is why you see this `Discussion`.
    case discussion = 999
}
