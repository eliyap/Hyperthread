//
//  CardHeaderCell.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 14/11/21.
//

import UIKit
import RealmSwift
import Twig
import SDWebImage

final class CardHeaderCell: UITableViewCell {
    
    public static let reuseID = "CardHeaderCell"
    override var reuseIdentifier: String? { Self.reuseID }
    
    /// Component
    let cardBackground = CardBackground(inset: CardTeaserCell.borderInset)
    let stackView = UIStackView()
    let userView = UserView()
    let tweetTextView = TweetTextView()
    let retweetView = RetweetView()
    let sdImageView = UIImageView()
    let metricsView = MetricsView()
    // TODO: add profile image

    private let inset: CGFloat = 6

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
//        stackView.addArrangedSubview(sdImageView)
        
        let arv = AspectRatioFrameView()
        arv.backgroundColor = .systemRed
        stackView.addArrangedSubview(arv)
        arv.constrain(to: stackView)
        arv.addSubview(sdImageView)
        
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
        tweetTextView.attributedText = tweet.fullText()
        retweetView.configure(tweet: tweet, realm: realm)
        metricsView.configure(tweet)
        
        if let imgURL = tweet.media.compactMap(\.url).first {
            sdImageView.sd_setImage(with: URL(string: imgURL))
            sdImageView.contentMode = .scaleAspectFit
//            NSLayoutConstraint.activate([
//                sdImageView.heightAnchor.constraint(equalToConstant: 100)
//            ])
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

final class AspectRatioFrameView: UIView {
    init() {
        super.init(frame: .zero)
    }
    
    private let aspectRatio: CGFloat = 0.667
    
    func constrain(to view: UIView) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            widthAnchor.constraint(equalTo: view.widthAnchor),
            heightAnchor.constraint(equalTo: widthAnchor, multiplier: aspectRatio),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
