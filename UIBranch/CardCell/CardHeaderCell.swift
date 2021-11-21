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
    let backgroundButton = UIButton()
    let stackView = UIStackView()
    let userView = UserView()
    let tweetTextView = TweetTextView()
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
        addSubview(backgroundButton)
        backgroundButton.layer.cornerRadius = inset * 2
        backgroundButton.layer.cornerCurve = .continuous
        backgroundButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: inset),
            backgroundButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -inset),
            backgroundButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: inset),
            backgroundButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -inset),
        ])
        
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
        stackView.addArrangedSubview(retweetView)
        stackView.addArrangedSubview(metricsView)
        
        /// Manually constrain to full width.
        NSLayoutConstraint.activate([
            metricsView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            metricsView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
        ])

        /// Apply default styling.
        backgroundButton.backgroundColor = .card
        backgroundButton.layer.borderWidth = 1.00
        backgroundButton.layer.borderColor = UIColor.secondarySystemFill.cgColor
    }

    public func configure(tweet: Tweet, author: User, realm: Realm) {
        userView.configure(tweet: tweet, user: author, timestamp: tweet.createdAt)
        tweetTextView.attributedText = tweet.fullText()
        retweetView.configure(tweet: tweet, realm: realm)
        metricsView.configure(tweet)
        
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
