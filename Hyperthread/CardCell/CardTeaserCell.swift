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
    let hairlineView = SpacedSeparator(vertical: .zero, horizontal: CardTeaserCell.ContentSpacing)
    let summaryView = SummaryView()
    
    var realmTokens: [NotificationToken] = []
    
    public static let ContentSpacing: CGFloat = 4
    
    public static let ContentInset: CGFloat = 9
    private let contentInsets: UIEdgeInsets = UIEdgeInsets(top: CardTeaserCell.ContentInset, left: CardTeaserCell.ContentInset, bottom: CardTeaserCell.ContentInset, right: CardTeaserCell.ContentInset)
    
    /// Since cards are stacked vertically in the table, halve the doubled insets to compensate.
    private let cardInsets = UIEdgeInsets(
        top: CardBackground.Inset / 2,
        left: CardBackground.Inset,
        bottom: CardBackground.Inset / 2,
        right: CardBackground.Inset
    )
    
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
            insets: cardInsets,
            /// Keep profile pic and card "concentric".
            cornerRadius: ProfileImageView.cornerRadius + CardTeaserCell.ContentInset
        )

        /// Configure Main Stack View.
        controller.view.addSubview(stackView)
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = Self.ContentSpacing
        let stackInsets = cardInsets + contentInsets
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: stackInsets.top),
            stackView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: stackInsets.left),
            stackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -stackInsets.right),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -stackInsets.bottom),
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

    public func configure(discussion: Discussion, realm: Realm) {
        let tweet: Tweet? = realm.tweet(id: discussion.id)
        guard let tweet = tweet else {
            TableLog.error("Could not find tweet with ID \(discussion.id)")
            assert(false)
            
            /// Fix layout in production.
            /// - Note: expressly passing "no media" fixes issue where `superTall` dimensions cause bad layout.
            albumVC.configure(media: [], picUrlString: nil)
            return
        }
        
        if let author = realm.user(id: tweet.authorID) {
            userView.configure(user: author)
        } else {
            TableLog.error("Could not find user with ID \(tweet.authorID)")
            assert(false)
        }
        
        tweetTextView.attributedText = tweet.attributedString
        retweetView.configure(tweet: tweet, realm: realm)
        summaryView.configure(discussion, realm: realm)
        albumVC.configure(tweet: tweet)
        
        /// Correct for strange spacing issue observed 22.02.02 by removing spacing from text view.
        /// Docs: https://developer.apple.com/documentation/uikit/uiview/1622648-alignmentrectinsets
        /// Zero by default.
        /// - Note: Issue was especially apparent when `tweetTextView` was directly above `retweetView` or `hairlineView`.
        ///         Hence we deliberately limit this special adjustment.
        if albumVC.view.isHidden {
            tweetTextView.bottomInset = 5
        } else {
            tweetTextView.bottomInset = .zero
        }
        
        tweetTextView.delegate = self
        cardBackground.configure(status: discussion.read)
        
        registerObservers(realm: realm, discussion: discussion, root: tweet)
    }
    
    private func registerObservers(realm: Realm, discussion: Discussion, root tweet: Tweet) -> Void {
        /// Release old observers, since cell is recycled.
        for realmToken in realmTokens {
            realmToken.invalidate()
        }
        
        /**
         UI code is run on the main thread, hence `realm` is also on the main thread,
         so we must use `DispatchQueue.main` to avoid invoking `realm` on the wrong thread.
         */
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                TableLog.warning("\(Self.self) is nil!")
                return
            }
            
            /// Protect against error "Cannot register notification blocks from within write transactions."
            guard realm.isInWriteTransaction == false else {
                assert(false, "realm.isInWriteTransaction true, if not avoided, this will crash!")
                return
            }
            
            let discussionToken = discussion.observe(self.updateTeaser)
            self.realmTokens.append(discussionToken)
            
            for mediaItem in tweet.media {
                let mediaToken = mediaItem.observe { [weak self] change in
                    self?.updateMedia(root: tweet)
                }
                self.realmTokens.append(mediaToken)
            }
        }
    }
    
    private func updateMedia(root tweet: Tweet) -> Void {
        albumVC.configure(tweet: tweet)
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
            let realm = makeRealm()
            let updated = realm.discussion(id: oldDiscussion.id)!
            summaryView.configure(updated, realm: realm)
            
            /// Update color when `readStatus` changes.
            cardBackground.configure(status: updated.read)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        for realmToken in realmTokens {
            realmToken.invalidate()
        }
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
