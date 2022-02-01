//
//  CardHeaderCell.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 14/11/21.
//

import UIKit
import RealmSwift
import Twig
import Combine

final class CardHeaderCell: ControlledCell {
    
    public static let reuseID = "CardHeaderCell"
    override var reuseIdentifier: String? { Self.reuseID }
    
    /// Combine communication line.
    private let line: CellEventLine = .init()
    private var cancellable: Set<AnyCancellable> = []

    /// Component views.
    let cardBackground = CardBackground()
    let stackView = UIStackView()
    let userView: UserView
    let tweetTextView = TweetTextView()
    let albumVC = AlbumController()
    let retweetView = RetweetView()
    let metricsView = MetricsView()
    
    private static let ContentInset: CGFloat = 9
    private let contentInsets = UIEdgeInsets(top: CardHeaderCell.ContentInset, left: CardHeaderCell.ContentInset, bottom: CardHeaderCell.ContentInset, right: CardHeaderCell.ContentInset)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.userView = .init(line: line)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        /// Do not change color when selected.
        selectionStyle = .none
        backgroundColor = .flat
        
        /// Configure background.
        controller.view.addSubview(cardBackground)
        cardBackground.constrain(
            to: safeAreaLayoutGuide,
            insets: CardBackground.EdgeInsets,
            cornerRadius: ProfileImageView.cornerRadius + CardHeaderCell.ContentInset
        )
        
        /// Configure Main Stack View.
        controller.view.addSubview(stackView)
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        let stackInsets = CardBackground.EdgeInsets + contentInsets
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: controller.view.topAnchor, constant: stackInsets.top),
            stackView.leftAnchor.constraint(equalTo: controller.view.leftAnchor, constant: stackInsets.left),
            stackView.rightAnchor.constraint(equalTo: controller.view.rightAnchor, constant: -stackInsets.right),
            stackView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor, constant: -stackInsets.bottom),
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
        
        line.events
            .sink { [weak self] event in
                switch event {
                case .usernameTouch(let userID):
                    self?.open(userID: userID)
                }
            }
            .store(in: &cancellable)
    }

    public func configure(tweet: Tweet, author: User, realm: Realm) {
        userView.configure(user: author)
        tweetTextView.attributedText = tweet.attributedString
        retweetView.configure(tweet: tweet, realm: realm)
        metricsView.configure(tweet)
        albumVC.configure(tweet: tweet)
        
        tweetTextView.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        cancellable.forEach { $0.cancel() }
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
