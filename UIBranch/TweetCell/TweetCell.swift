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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class UserView: UIStackView {
    
    private let nameLabel = UILabel()
    private let handleLabel = UILabel()
    private let timestampLabel = UILabel()
    fileprivate let _spacing: CGFloat = 5

    init() {
        super.init(frame: .zero)
        axis = .horizontal
        alignment = .firstBaseline
        spacing = _spacing

        translatesAutoresizingMaskIntoConstraints = false
        
        addArrangedSubview(nameLabel)
        addArrangedSubview(handleLabel)
        addArrangedSubview(timestampLabel)

        nameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        nameLabel.adjustsFontForContentSizeCategory = true
        
        handleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        handleLabel.adjustsFontForContentSizeCategory = true
        handleLabel.textColor = .secondaryLabel

        timestampLabel.adjustsFontForContentSizeCategory = true
        timestampLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        timestampLabel.textColor = .secondaryLabel
        
        /// Allow handle to be truncated if space is insufficient.
        /// We want this to be truncated before the username is.
        handleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    public func configure(user: User, timestamp: Date) {
        nameLabel.text = user.name
        handleLabel.text = "@" + user.handle
        timestampLabel.text = DateFormatter.localizedString(from: timestamp, dateStyle: .short, timeStyle: .short)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
