//
//  Tweet Shorthand.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 17/1/22.
//

import Foundation
import Twig

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

extension Tweet {
    var isRetweet: Bool { retweeting != nil }
    var isQuote: Bool { quoting != nil }
    var isReply: Bool { replying_to != nil }
}

extension Tweet {
    var picUrlString: String? {
        guard let urls = entities?.urls else { return nil }
        return urls.map(\.display_url).last { $0.starts(with: "pic.twitter.com/") }
    }
}

extension Tweet {
    var referenced: [ID] {
        [
            replying_to,
            retweeting,
            quoting
        ].compactMap { $0 }
    }
    
    var danglingReferences: Set<Tweet.ID> {
        var result: Set<Tweet.ID> = .init()
        if dangling.contains(.reply) {
            guard let replyID = replying_to else {
                ModelLog.error("Tweet \(id) has dangling reply but no replying_to ID")
                assert(false)
                return result
            }
            result.insert(replyID)
        }
        if dangling.contains(.quote) {
            guard let quoteID = quoting else {
                ModelLog.error("Tweet \(id) has dangling quote but no quoting ID")
                assert(false)
                return result
            }
            result.insert(quoteID)
        }
        if dangling.contains(.retweet) {
            guard let retweetID = retweeting else {
                ModelLog.error("Tweet \(id) has dangling retweet but no retweeting ID")
                assert(false)
                return result
            }
            result.insert(retweetID)
        }
        return result
    }
}
