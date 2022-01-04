//
//  CardHeaderCell.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 14/11/21.
//

import UIKit
import RealmSwift
import Twig

final class CardHeaderCell: ControlledCell {
    
    public static let reuseID = "CardHeaderCell"
    override var reuseIdentifier: String? { Self.reuseID }
    
    /// Component
    let cardBackground = CardBackground()
    let stackView = UIStackView()
    let userView = UserView()
    let tweetTextView = TweetTextView()
    let albumVC = AlbumController()
    let retweetView = RetweetView()
    let metricsView = MetricsView()
    // TODO: add profile image
    
    private let inset: CGFloat = 6
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        /// Do not change color when selected.
        selectionStyle = .none
        backgroundColor = .flat
        
        /// Configure background.
        controller.view.addSubview(cardBackground)
        cardBackground.constrain(to: safeAreaLayoutGuide)
        
        /// Configure Main Stack View.
        controller.view.addSubview(stackView)
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: controller.view.topAnchor, constant: inset * 2),
            stackView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor, constant: inset * 2),
            stackView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor, constant: -inset * 2),
            stackView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor, constant: -inset * 2),
        ])

        stackView.addArrangedSubview(userView)
        stackView.addArrangedSubview(tweetTextView)
        
        controller.addChild(albumVC)
        stackView.addArrangedSubview(albumVC.view)
        albumVC.didMove(toParent: controller)
        albumVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            albumVC.view.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            albumVC.view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
        ])
        
        stackView.addArrangedSubview(retweetView)
        stackView.addArrangedSubview(metricsView)
        
        /// Manually constrain to full width.
        NSLayoutConstraint.activate([
            metricsView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            metricsView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
        ])
        
        /// Apply default styling.
        cardBackground.backgroundColor = .card
        cardBackground.layer.borderWidth = 1.00
        cardBackground.layer.borderColor = UIColor.secondarySystemFill.cgColor
    }

    public func configure(tweet: Tweet, author: User, realm: Realm) {
        userView.configure(tweet: tweet, user: author, timestamp: tweet.createdAt)
        tweetTextView.attributedText = tweet.attributedString
        retweetView.configure(tweet: tweet, realm: realm)
        metricsView.configure(tweet)
        albumVC.configure(tweet: tweet)
        
        tweetTextView.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/**
 Re-direct URL taps to open link in Safari.
 */
extension CardHeaderCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        open(url: URL)
        return false
    }
}

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
