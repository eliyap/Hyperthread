//
//  PublicMetrics.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 16/12/21.
//

import Foundation
import RealmSwift
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
    
    override required init() {}
    
    init(raw: RawPublicMetrics) {
        like_count = raw.like_count
        retweet_count = raw.retweet_count
        reply_count = raw.reply_count
        quote_count = raw.quote_count
    }

    internal init(
        like_count: Int,
        retweet_count: Int,
        reply_count: Int,
        quote_count: Int
    ) {
        self.like_count = like_count
        self.retweet_count = retweet_count
        self.reply_count = reply_count
        self.quote_count = quote_count
    }
}
