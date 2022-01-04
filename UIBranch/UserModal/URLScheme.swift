//
//  URLScheme.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 4/1/22.
//

import Foundation

struct HashtagURL {
    public static let scheme = "hashtag"
    static func urlString(tag: Tag) -> String {
        "\(scheme)://\(tag.tag)"
    }
    static func tag(from url: URL) -> User.ID {
        return url.host ?? ""
    }
}

struct UserURL {
    public static let scheme = "handle"
    static func urlString(mention: Mention) -> String {
        "\(scheme)://\(mention.id)"
    }
    static func id(from url: URL) -> User.ID {
        url.host ?? ""
    }
}
