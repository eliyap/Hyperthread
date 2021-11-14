//
//  CardCell.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 14/11/21.
//

import UIKit
import RealmSwift
import Twig

final class CardCell: UITableViewCell {
    
    public static let reuseID = "CardCell"
    override var reuseIdentifier: String? { Self.reuseID }
    
    /// Component
    let backgroundButton = UIButton()
    let stackView = UIStackView()
    let replyView = ReplyView()
    let userView = UserView()
    let tweetLabel = UILabel()
    let retweetView = RetweetView()
    let metricsView = MetricsView()
    // TODO: add profile image

    private let inset: CGFloat = 6

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        /// Do not change color when selected.
        selectionStyle = .none
        
        /// Configure background.
        backgroundButton.backgroundColor = .secondarySystemBackground
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
    }

    public func configure(tweet: Tweet, author: User, realm: Realm) {
        userView.configure(user: author, timestamp: tweet.createdAt)
        tweetLabel.text = tweet.text
        replyView.configure(tweet: tweet, realm: realm)
        retweetView.configure(tweet: tweet, realm: realm)
        metricsView.configure(tweet)
    }
    
    func style(selected: Bool) -> Void {
        if selected {
            UIView.animate(withDuration: 0.25) { [weak self] in
                guard let self = self else { 
                    assert(false, "self is nil")
                    return 
                }
                self.stackView.transform = CGAffineTransform(translationX: 0, y: -self.inset / 2)
                self.backgroundButton.transform = CGAffineTransform(translationX: 0, y: -self.inset / 2)
//                self.backgroundButton.backgroundColor = .systemRed
                self.backgroundButton.layer.shadowColor = UIColor.black.cgColor
                self.backgroundButton.layer.shadowOpacity = 0.3
                self.backgroundButton.layer.shadowRadius = self.inset / 2
                self.backgroundButton.layer.shadowOffset = CGSize(width: .zero, height: self.inset / 2)
            }
        } else {
            UIView.animate(withDuration: 0.25) { [weak self] in
                guard let self = self else { 
                    assert(false, "self is nil")
                    return 
                }
                self.stackView.transform = CGAffineTransform(translationX: 0, y: 0)
                self.backgroundButton.transform = CGAffineTransform(translationX: 0, y: 0)
//                self.backgroundButton.backgroundColor = .secondarySystemBackground
                self.backgroundButton.layer.shadowColor = UIColor.black.cgColor
                self.backgroundButton.layer.shadowOpacity = 0
                self.backgroundButton.layer.shadowRadius = 0
                self.backgroundButton.layer.shadowOffset = CGSize.zero
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
