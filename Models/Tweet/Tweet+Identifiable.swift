//
//  Tweet+Identifiable.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 17/1/22.
//

import Foundation
import Twig

extension Tweet: ReplyIdentifiable {
    var replyID: String? { replying_to }
}

extension Tweet: RetweetIdentifiable {
    var retweetID: String? { retweeting }
}
