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
    let frameView = AspectRatioFrameView()
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
        tweetTextView.attributedText = tweet.fullText()
        retweetView.configure(tweet: tweet, realm: realm)
        metricsView.configure(tweet)
        
        if let media = tweet.media.first(where: {$0.url != nil}) {
            frameView.configure(media: media)
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
    
    private let imageView = UIImageView()
    
    /// Allows us to pin the image's height or width to our own.
    private var heightConstraint: NSLayoutConstraint! = nil
    private var widthConstraint: NSLayoutConstraint! = nil
    
    /// Set's the image aspect ratio.
    var aspectRatioConstraint: NSLayoutConstraint! = nil
    
    /// Maximum frame aspect ratio.
    private let threshholdAR: CGFloat = 0.667
    
    init() {
        super.init(frame: .zero)
        /// Defuse implicitly unwrapped `nil`s.
        heightConstraint = imageView.heightAnchor.constraint(equalTo: self.heightAnchor)
        widthConstraint = imageView.widthAnchor.constraint(equalTo: self.widthAnchor)
        aspectRatioConstraint = heightAnchor.constraint(equalTo: self.widthAnchor, multiplier: threshholdAR)
        
        addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
    }
    
    func constrain(to view: UIView) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            widthAnchor.constraint(equalTo: view.widthAnchor),
            aspectRatioConstraint,
        ])
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    
    func configure(media: Media) -> Void {
        if let urlString = media.url {
            imageView.sd_setImage(with: URL(string: urlString))
            if media.aspectRatio > self.threshholdAR {
                heightConstraint.isActive = true
                widthConstraint.isActive = false
                setAspectRatio(to: threshholdAR)
            } else {
                heightConstraint.isActive = false
                widthConstraint.isActive = true
                setAspectRatio(to: media.aspectRatio)
            }
        }
    }
    
    private func setAspectRatio(to value: CGFloat) -> Void {
        NSLayoutConstraint.deactivate([aspectRatioConstraint])
        aspectRatioConstraint = heightAnchor.constraint(equalTo: widthAnchor, multiplier: value)
        NSLayoutConstraint.activate([aspectRatioConstraint])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
