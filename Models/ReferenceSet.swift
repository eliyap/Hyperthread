//
//  ReferenceSet.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 17/1/22.
//

import Foundation

/**
 Represents the set of references held by a `Tweet`.
 */
internal struct ReferenceSet: OptionSet {
    var rawValue: Int
    
    typealias RawValue = Int
    
    static let reply = Self(rawValue: 1 << 0)
    static let quote = Self(rawValue: 1 << 1)
    static let retweet = Self(rawValue: 1 << 2)
    
    static let empty: Self = []
    static let all: Self = [.reply, .quote, .retweet]
}
