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
    
    public static let reuseID = "TweetCell"
    override var reuseIdentifier: String? { Self.reuseID }
    
    let depthStack = UIStackView()
    let depthSpacer = UIView()
    
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
        
        /// Configure Depth Stack View.
        contentView.addSubview(depthStack)
        depthStack.axis = .horizontal
        depthStack.translatesAutoresizingMaskIntoConstraints = false
        depthStack.addArrangedSubview(depthSpacer)
        depthStack.addArrangedSubview(stackView)
        NSLayoutConstraint.activate([
            depthStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            depthStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            depthStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            depthStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])

        /// Configure Main Stack View.
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(replyView)
        stackView.addArrangedSubview(userView)
        stackView.addArrangedSubview(tweetLabel)
        stackView.addArrangedSubview(retweetView)
        stackView.addArrangedSubview(metricsView)
        
        /// Manually constrain to full width.
        NSLayoutConstraint.activate([
            metricsView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            metricsView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
        ])

        /// Configure Label
        tweetLabel.font = UIFont.preferredFont(forTextStyle: .body)
        tweetLabel.adjustsFontForContentSizeCategory = true

        /// Allow tweet to wrap across lines.
        tweetLabel.lineBreakMode = .byWordWrapping
        tweetLabel.numberOfLines = 0 /// Yes, really.
        
        backgroundColor = .flat
    }

    public func configure(node: Node, author: User, realm: Realm) {
        userView.configure(tweet: node.tweet, user: author, timestamp: node.tweet.createdAt)
        tweetLabel.text = node.tweet.text
        replyView.configure(tweet: node.tweet, realm: realm)
        retweetView.configure(tweet: node.tweet, realm: realm)
        metricsView.configure(node.tweet)
        
        NSLayoutConstraint.activate([
            depthSpacer.widthAnchor.constraint(equalToConstant: 10 * CGFloat(node.depth))
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
