//
//  CardTeaserCell.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 21/11/21.
//

import UIKit
import RealmSwift
import Twig

final class CardTeaserCell: UITableViewCell {
    
    public static let reuseID = "CardTeaserCell"
    override var reuseIdentifier: String? { Self.reuseID }
    
    /// Component
    let cardBackground = CardBackground(inset: CardTeaserCell.borderInset)
    let stackView = UIStackView()
    let userView = UserView()
    let tweetTextView = TweetTextView()
    let retweetView = RetweetView()
    let metricsView = MetricsView()
    // TODO: add profile image

    public static let borderInset: CGFloat = 6
    private lazy var inset: CGFloat = CardTeaserCell.borderInset

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
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
        stackView.addArrangedSubview(retweetView)
        stackView.addArrangedSubview(metricsView)
        
        /// Manually constrain to full width.
        NSLayoutConstraint.activate([
            metricsView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            metricsView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
        ])

        /// Apply default styling.
        self.resetStyle()
    }

    public func configure(tweet: Tweet, author: User, realm: Realm) {
        userView.configure(tweet: tweet, user: author, timestamp: tweet.createdAt)
        tweetTextView.attributedText = tweet.fullText()
        retweetView.configure(tweet: tweet, realm: realm)
        metricsView.configure(tweet)
        
        tweetTextView.delegate = self
    }
    
    func style(selected: Bool) -> Void {
        UIView.animate(withDuration: 0.25) { [weak self] in
            guard let self = self else {
                assert(false, "self is nil")
                return
            }
            /// By changing the radius, offset, and transform at the same time, we can grow / shrink the shadow in place,
            /// creating a "lifting" illusion.
            if selected {
                self.styleSelected()
            } else {
                self.resetStyle()
            }
        }
    }
    
    public func styleSelected() -> Void {
        let shadowSize = self.inset * 0.75
        
        stackView.transform = CGAffineTransform(translationX: 0, y: -shadowSize)
        cardBackground.transform = CGAffineTransform(translationX: 0, y: -shadowSize)
        cardBackground.layer.shadowColor = UIColor.black.cgColor
        cardBackground.layer.shadowOpacity = 0.3
        cardBackground.layer.shadowRadius = shadowSize
        cardBackground.layer.shadowOffset = CGSize(width: .zero, height: shadowSize)
        
        cardBackground.backgroundColor = .cardSelected
        cardBackground.layer.borderWidth = 0
        cardBackground.layer.borderColor = UIColor.secondarySystemFill.cgColor
    }
    
    public func resetStyle() -> Void {
        stackView.transform = CGAffineTransform(translationX: 0, y: 0)
        cardBackground.transform = CGAffineTransform(translationX: 0, y: 0)
        cardBackground.layer.shadowColor = UIColor.black.cgColor
        cardBackground.layer.shadowOpacity = 0
        cardBackground.layer.shadowRadius = 0
        cardBackground.layer.shadowOffset = CGSize.zero
        
        cardBackground.backgroundColor = .card
        cardBackground.layer.borderWidth = 1.00
        cardBackground.layer.borderColor = UIColor.secondarySystemFill.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/**
 Re-direct URL taps to open link in Safari.
 */
extension CardTeaserCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL)
        return false
    }
}