//
//  TweetCell.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 13/11/21.
//

import UIKit
import RealmSwift
import Twig

final class TweetCell: UITableViewCell {
    
    public static let reuseID = "DiscussionCell"
    override var reuseIdentifier: String? { Self.reuseID }
    
    /// Component Views
    let stackView = UIStackView()
    let replyView = ReplyView()
    let userView = UserView()
    let tweetLabel = UILabel()
    let retweetView = RetweetView()
    let metricsView = MetricsView()
    // TODO: add profile image
    // TODO: add retweet marker
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        /// Configure Main Stack View
        contentView.addSubview(stackView)
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])

        stackView.addArrangedSubview(replyView)
        stackView.addArrangedSubview(userView)
        stackView.addArrangedSubview(tweetLabel)
        stackView.addArrangedSubview(retweetView)
        stackView.addArrangedSubview(metricsView)

        /// Configure Label
        tweetLabel.font = UIFont.preferredFont(forTextStyle: .body)
        tweetLabel.adjustsFontForContentSizeCategory = true

        /// Allow tweet to wrap across lines.
        tweetLabel.lineBreakMode = .byWordWrapping
        tweetLabel.numberOfLines = 0 /// Yes, really.
    }

    public func configure(tweet: Tweet, author: User, realm: Realm) {
        userView.configure(user: author, timestamp: tweet.createdAt)
        tweetLabel.text = tweet.text
        replyView.configure(tweet: tweet, realm: realm)
        retweetView.configure(tweet: tweet, realm: realm)
        metricsView.configure(tweet)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class MetricsView: UIStackView {
    let replyButton = ReplyButton()
    let retweetButton = RetweetButton()
    let likeButton = LikeButton()
    let timestampLabel = UILabel()

    fileprivate let _spacing: CGFloat = 5
    
    init() {
        super.init(frame: .zero)
        axis = .horizontal
        distribution = .fillEqually
        alignment = .center
        spacing = _spacing

        addArrangedSubview(replyButton)
        addArrangedSubview(retweetButton)
        addArrangedSubview(likeButton)
        addArrangedSubview(timestampLabel)

        timestampLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        timestampLabel.adjustsFontForContentSizeCategory = true
    }

    func configure(_ tweet: Tweet) {
        replyButton.configure(tweet)
        retweetButton.configure(tweet)
        likeButton.configure(tweet)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LabelledButton: UIButton {
    
    
    init(symbolName: String) {
        super.init(frame: .zero)
        setImage(UIImage(systemName: symbolName), for: .normal)
        setPreferredSymbolConfiguration(.init(paletteColors: [.secondaryLabel]), forImageIn: .normal)
        setTitleColor(.secondaryLabel, for: .normal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ReplyButton: LabelledButton {
    init() {
        super.init(symbolName: "arrowshape.turn.up.left.fill")
    }

    func configure(_ tweet: Tweet) {
        setTitle("\(tweet.metrics.reply_count)", for: .normal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class RetweetButton: LabelledButton {
    init() {
        super.init(symbolName: "arrow.2.squarepath")
    }

    func configure(_ tweet: Tweet) {
        setTitle("\(tweet.metrics.retweet_count)", for: .normal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class LikeButton: LabelledButton {
    init() {
        super.init(symbolName: "heart.fill")
    }

    func configure(_ tweet: Tweet) {
        
        setTitle("\(tweet.metrics.like_count)", for: .normal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
