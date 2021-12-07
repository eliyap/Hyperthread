//
//  SummaryLine.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 21/11/21.
//

import UIKit
import RealmSwift

final class SummaryView: UIStackView {
    
    private let replyButton = ReplyButton()
    private let retweetButton = RetweetButton()
    private let likeButton = LikeButton()
    private let iconView = IconView(sfSymbol: "heart")
    public let timestampButton = TimestampButton()

    init() {
        super.init(frame: .zero)
        axis = .horizontal
        distribution = .fill
        alignment = .center
        
        translatesAutoresizingMaskIntoConstraints = false

        addArrangedSubview(replyButton)
        addArrangedSubview(retweetButton)
        addArrangedSubview(likeButton)
        addArrangedSubview(iconView)
        addArrangedSubview(UIView())
        addArrangedSubview(timestampButton)
    }

    func configure(_ discussion: Discussion, realm: Realm) {
        if discussion.tweetCount == 1 {
            replyButton.isHidden = false
            retweetButton.isHidden = false
            likeButton.isHidden = false
            iconView.isHidden = true
            
            /// Simply show the metrics.
            let tweet = discussion.tweets.first!
            replyButton.configure(tweet)
            retweetButton.configure(tweet)
            likeButton.configure(tweet)
        } else if discussion.tweetCount == 2 {
            replyButton.isHidden = true
            retweetButton.isHidden = true
            likeButton.isHidden = true
            iconView.isHidden = false
            
            /// Configure with an appropriate symbol.
            let nonRetweets = discussion.tweets.filter { $0.retweeting == nil }
            guard nonRetweets.count == 2 else {
                Swift.debugPrint("Wrong number of tweets!")
                return
            }
            let onlyReply = discussion.tweets[1]
            if onlyReply.primaryReference == onlyReply.replying_to {
                iconView.imageView.setImage(to: "arrowshape.turn.up.left.fill")
            } else if onlyReply.primaryReference == onlyReply.quoting {
                iconView.imageView.setImage(to: "quote.bubble.fill")
            } else {
                TableLog.error("Invalid state, should be retweet or reply!")
            }
            
            iconView.setText(to: realm.user(id: onlyReply.authorID)!.name)
        } else {
            replyButton.isHidden = true
            retweetButton.isHidden = true
            likeButton.isHidden = true
            iconView.isHidden = false
            
            iconView.imageView.setImage(to: "bubble.left.and.bubble.right.fill")
            
            /// Exclude the original from the count.
            iconView.setText(to: "\(discussion.tweetCount - 1) tweets")
        }
        timestampButton.configure(discussion)
    }
    
    required init(coder: NSCoder) {
        fatalError("No.")
    }
}
