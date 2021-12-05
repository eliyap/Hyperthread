//
//  CardHeaderCell.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 14/11/21.
//

import UIKit
import RealmSwift
import Twig

final class CardHeaderCell: UITableViewCell {
    
    public static let reuseID = "CardHeaderCell"
    override var reuseIdentifier: String? { Self.reuseID }
    
    /// Component
    let cardBackground = CardBackground(inset: CardTeaserCell.borderInset)
    let stackView = UIStackView()
    let userView = UserView()
    let tweetTextView = TweetTextView()
    let frameView = AspectRatioFrameView()
    let retweetView = RetweetView()
    let metricsView = MetricsView()
    // TODO: add profile image
    
    private let inset: CGFloat = 6
    
    var contentViewController: UIViewController
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.contentViewController = UIViewController()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentViewController.view.layer.borderWidth = 2
        contentViewController.view.layer.borderColor = UIColor.red.cgColor
        
        /// Do not change color when selected.
        selectionStyle = .none
        backgroundColor = .flat
        
        /// Configure background.
        addSubview(cardBackground)
        cardBackground.constrain(to: safeAreaLayoutGuide)
        
        /// Configure Main Stack View
        contentView.addSubview(stackView)
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: inset * 2),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset * 2),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset * 2),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -inset * 2),
        ])

        stackView.addArrangedSubview(userView)
        stackView.addArrangedSubview(tweetTextView)
        stackView.addArrangedSubview(frameView)
        stackView.addArrangedSubview(retweetView)
        stackView.addArrangedSubview(metricsView)
        
        /// Manually constrain to full width.
        NSLayoutConstraint.activate([
            metricsView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            metricsView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
        ])
        
        frameView.constrain(to: stackView)

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
        
        if let media = tweet.media.first(where: {$0.url != nil}) {
            frameView.configure(media: media)
            frameView.isHidden = false
        } else {
            frameView.isHidden = true
        }
        
        if tweet.media.count > 1 {
            #warning("TODO: show all.")
            Swift.debugPrint("\(tweet.media.count) media items found.")
        }
        
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
        UIApplication.shared.open(URL)
        return false
    }
}
