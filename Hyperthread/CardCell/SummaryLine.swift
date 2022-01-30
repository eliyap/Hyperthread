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

    @MainActor
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
            
            /** It's common for there to be only 1 response in a discussion.
                In this case, show who responded.
                
                Usually this occurs someone you follow quotes someone you don't.
                In this case, this shows the person who "pushed" this to your feed.
             */
            let nonRetweets = discussion.tweets
                /// - Note: Unsorted `tweets` can be out of order, resulting in mis-attributing the reply.
                .sorted(by: Tweet.chronologicalSort)
                .filter { $0.retweeting == nil }
                
            guard nonRetweets.count == 2 else {
                assert(false, "Wrong number of tweets!")
                return
            }
            
            /// Configure with an appropriate symbol.
            let onlyResponse = nonRetweets[1]
            if onlyResponse.primaryReference == onlyResponse.replying_to {
                iconView.imageView.setImage(to: "arrowshape.turn.up.left.fill")
            } else if onlyResponse.primaryReference == onlyResponse.quoting {
                iconView.imageView.setImage(to: "quote.bubble.fill")
            } else {
                TableLog.error("Invalid state, should be retweet or reply!")
            }
            
            /// Name the responder in the summary line.
            iconView.setText(to: realm.user(id: onlyResponse.authorID)!.name)
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
