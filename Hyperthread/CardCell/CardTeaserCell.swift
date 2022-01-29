//
//  CardTeaserCell.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 21/11/21.
//

import UIKit
import RealmSwift
import Realm
import Twig
import Combine

final class CardTeaserCell: ControlledCell {
    
    public static let reuseID = "CardTeaserCell"
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
    let hairlineView = SpacedSeparator(vertical: CardTeaserCell.borderInset, horizontal: CardTeaserCell.borderInset)
    let summaryView = SummaryView()
    
    var token: NotificationToken? = nil
    
    public static let borderInset: CGFloat = 6
    private lazy var inset: CGFloat = CardTeaserCell.borderInset
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.userView = .init(line: line)
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
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: inset * 2),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset * 2),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset * 2),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -inset * 2),
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
        stackView.addArrangedSubview(hairlineView)
        hairlineView.constrain(to: stackView)
        
        stackView.addArrangedSubview(summaryView)
        /// Manually constrain to full width.
        NSLayoutConstraint.activate([
            summaryView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            summaryView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
        ])

        /// Apply default styling.
        self.resetStyle()
        
        line.events
            .sink { [weak self] event in
                switch event {
                case .usernameTouch(let userID):
                    self?.handleUsernameTouch(userID: userID)
                }
            }
            .store(in: &cancellable)
    }
    
    private func handleUsernameTouch(userID: User.ID) -> Void {
        open(userID: userID)
    }

    public func configure(discussion: Discussion, tweet: Tweet, author: User?, realm: Realm) {
        userView.configure(user: author)
        tweetTextView.attributedText = tweet.attributedString
        retweetView.configure(tweet: tweet, realm: realm)
        summaryView.configure(discussion, realm: realm)
        
        tweetTextView.delegate = self
        cardBackground.configure(status: discussion.read)
        
        albumVC.configure(tweet: tweet)
        
        /// Release old observer.
        if let token = token {
            token.invalidate()
        }
        
        /**
         `observe` cannot be called in a `write` transaction, which primarily occurs when `Airport` adds objects.
         See discussion https://github.com/realm/realm-cocoa/issues/4818
         
         To avoid conflicting with `Airport`, we **use the same scheduler**,
         so that by the time our work comes up, the write is guaranteed to be complete.
         Source: https://github.com/realm/realm-cocoa/issues/4818#issuecomment-489889711
         */
        Airport.scheduler.async { [weak self] in
            guard let self = self else {
                TableLog.warning("\(Self.self) is nil!")
                return
            }
            
            /// Protect against error "Cannot register notification blocks from within write transactions."
            guard realm.isInWriteTransaction == false else {
                assert(false, "realm.isInWriteTransaction true, if not avoided, this will crash!")
                return
            }
            
            self.token = discussion.observe(self.updateTeaser)
        }
    }
    
    private func updateTeaser(_ change: ObjectChange<Discussion>) -> Void {
        guard case let .change(oldDiscussion, properties) = change else { return }
        
        /// Update `updatedAt` timestamp.
        if let updatedAtChange = properties.first(where: {$0.name == Discussion.updatedAtPropertyName}) {
            guard let newDate = updatedAtChange.newValue as? Date else {
                Swift.debugPrint("Error: unexpected type! \(type(of: updatedAtChange.newValue))")
                return
            }
            summaryView.timestampButton.configure(newDate)
        }
        
        
        if properties.contains(where: {
            $0.name == Discussion.conversationsPropertyName
            || $0.name == Discussion.tweetsDidChangeKey
        }) {
            /// Fetch discussion anew to get updated tweet count.
            let realm = try! Realm()
            let updated = realm.discussion(id: oldDiscussion.id)!
            summaryView.configure(updated, realm: realm)
            
            /// Update color when `readStatus` changes.
            cardBackground.configure(status: updated.read)
        }
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
        
        cardBackground.styleSelected()
    }
    
    public func resetStyle() -> Void {
        stackView.transform = CGAffineTransform(translationX: 0, y: 0)
        cardBackground.transform = CGAffineTransform(translationX: 0, y: 0)
        cardBackground.layer.shadowColor = UIColor.black.cgColor
        cardBackground.layer.shadowOpacity = 0
        cardBackground.layer.shadowRadius = 0
        cardBackground.layer.shadowOffset = CGSize.zero
        
        cardBackground.styleDefault()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        token?.invalidate()
        TableLog.debug("\(Self.description()) de-initialized.", print: true, true)
        cancellable.forEach { $0.cancel() }
    }
}

/**
 Re-direct URL taps to open link in Safari.
 */
extension CardTeaserCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        open(url: URL)
        return false
    }
}
