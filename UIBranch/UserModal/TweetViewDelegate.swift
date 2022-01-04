//
//  TweetViewDelegate.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 4/1/22.
//

import Foundation
import UIKit

protocol TweetViewDelegate {
    func open(userID: User.ID) -> Void
    func open(hashtag: String) -> Void
}

extension TweetViewDelegate {
    func open(url: URL) -> Void {
        switch url.scheme {
        case UserURL.scheme:
            open(userID: UserURL.id(from: url))
        case HashtagURL.scheme:
            open(hashtag: HashtagURL.tag(from: url))
        default:
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                showAlert(message: "Failed to open url: \(url.absoluteString)")
            }
        }
    }
}
