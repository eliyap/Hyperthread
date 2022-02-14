//
//  TweetCell.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 13/11/21.
//

import UIKit
import RealmSwift
import Twig
import Combine

final class TweetCell: ControlledCell {
    
    public static let reuseID = "TweetCell"
    override var reuseIdentifier: String? { Self.reuseID }
    
    /// Indentation views.
    private let depthStack = UIStackView()
    private let colorMarker = ColorMarkerView()
    private let depthSpacer = UIView()
    
    /// Combine communication line.
    private let line: CellEventLine = .init()
    private var cancellable: Set<AnyCancellable> = []

    /// Tweet component views.
    private let stackView = UIStackView()
    private let userView: UserView
    private let tweetTextView: TweetTextView = .init()
    private let albumVC: AlbumController = .init()
    private var quoteView: QuoteView? = nil
    private let retweetView: RetweetView = .init()
    private let metricsView: MetricsView = .init()
    private let triangleView: TriangleView
    
    /// Variable Constraint.
    var indentConstraint: NSLayoutConstraint
    
    public static let ContentInset: CGFloat = CardTeaserCell.ContentInset /// Use same insets for consistency.
    private let contentInsets = UIEdgeInsets(top: TweetCell.ContentInset, left: TweetCell.ContentInset, bottom: TweetCell.ContentInset, right: TweetCell.ContentInset)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.userView = .init(line: line)
        
        let triangleSize = Self.ContentInset * 1.5
        self.triangleView = TriangleView(size: triangleSize)
        self.indentConstraint = depthSpacer.widthAnchor.constraint(equalToConstant: .zero)

        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
//        addSubview(triangleView)
//        triangleView.constrain(to: safeAreaLayoutGuide)
        
        /// Set delegate so we can route custom URL schemes.
        tweetTextView.delegate = self
        
        /// Configure Depth Stack View.
        controller.view.addSubview(depthStack)
        depthStack.axis = .horizontal
        depthStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            depthStack.topAnchor.constraint(equalTo: controller.view.topAnchor, constant: contentInsets.top),
            depthStack.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor, constant: -contentInsets.bottom),
            depthStack.leftAnchor.constraint(equalTo: controller.view.leftAnchor, constant: contentInsets.left),
            depthStack.rightAnchor.constraint(equalTo: controller.view.rightAnchor, constant: -contentInsets.right),
        ])

        /// Add spacer, which causes "indentation" in the cell view.
        depthStack.addArrangedSubview(depthSpacer)
        NSLayoutConstraint.activate([indentConstraint])
        
        /// Add color bar.
        depthStack.addArrangedSubview(colorMarker)
        colorMarker.constrain()
        NSLayoutConstraint.activate([
            colorMarker.heightAnchor.constraint(equalTo: depthStack.heightAnchor),
            colorMarker.topAnchor.constraint(equalTo: depthStack.topAnchor),
            colorMarker.bottomAnchor.constraint(equalTo: depthStack.bottomAnchor),
        ])
        
        /// Configure Main Stack View.
        depthStack.addArrangedSubview(stackView)
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(userView)
        stackView.addArrangedSubview(tweetTextView)
        
        /// Configure album view.
        controller.addChild(albumVC)
        stackView.addArrangedSubview(albumVC.view)
        albumVC.didMove(toParent: controller)
        albumVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            albumVC.view.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            albumVC.view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
        ])
        
        /// Special case: must request album be "as tall as possible".
        let atap = albumVC.view.heightAnchor.constraint(equalToConstant: .superTall)
        atap.isActive = true
        atap.priority = .defaultLow
        
        stackView.addArrangedSubview(retweetView)
        stackView.addArrangedSubview(metricsView)
        
        /// Manually constrain to full width.
        NSLayoutConstraint.activate([
            metricsView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            /// Add card padding so that timestamp labels are vertically aligned with the `CardHeaderCell`.
            metricsView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: -CardBackground.Inset),
        ])
        
        /// Ensure glyph size doesn't bug out.
        depthStack.spacing = .zero
        depthSpacer.setContentHuggingPriority(.required, for: .horizontal)
        colorMarker.setContentHuggingPriority(.required, for: .horizontal)
        stackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        /// Ensure glyph size doesn't bug out.
        depthSpacer.setContentCompressionResistancePriority(.required, for: .horizontal)
        colorMarker.setContentCompressionResistancePriority(.required, for: .horizontal)
        stackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        stackView.subviews.forEach {
            $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }
        
        backgroundColor = .flat
        
        /// Hide by default.
        triangleView.isHidden = true
        
        line.events
            .sink { [weak self] event in
                switch event {
                case .usernameTouch(let userID):
                    self?.open(userID: userID)
                }
            }
            .store(in: &cancellable)
    }

    /// Arbitrary number. Test Later.
    private let maxDepth = 14
    private let indentSize: CGFloat = 10
    public func configure(node: Node, realm: Realm, requester: DiscusssionRequestable?) {
        switch node.tweet {
        case .available(let tweet, let author):
            userView.configure(user: author)
            tweetTextView.attributedText = tweet.fullText(context: node)
            retweetView.configure(tweet: tweet, realm: realm)
            metricsView.configure(tweet)
            albumVC.configure(tweet: tweet)
            
            userView.isHidden = false
            retweetView.isHidden = false
            metricsView.isHidden = false
            /// Let `albumVC` decide `isHidden`.
            
            configureQuoteReply(tweet: tweet, realm: realm, requester: requester)
        case .unavailable(let id):
            tweetTextView.attributedText = Tweet.notAvailableAttributedString(id: id)
            userView.isHidden = true
            retweetView.isHidden = true
            metricsView.isHidden = true
            albumVC.view.isHidden = true
        }
        
        /// Set indentation depth, decrementing to account for 1 indexing.
        let depth = min(maxDepth, node.depth - 1)
        let indent = indentSize * CGFloat(depth)
        let newConstraint = depthSpacer.widthAnchor.constraint(equalToConstant: indent)
        replace(object: self, on: \.indentConstraint, with: newConstraint)
        
        separatorInset = UIEdgeInsets(top: 0, left: indent + indentSize, bottom: 0, right: 0)
        
        /// Use non-capped depth to determine color.
        colorMarker.configure(node: node)
    }
    
    private func configureQuoteReply(tweet: Tweet, realm: Realm, requester: DiscusssionRequestable?) -> Void {
        guard let quoting = tweet.quoting, tweet.isReply else {
            quoteView?.isHidden = false
            return
        }
        
        /// Only load if quote is present!
        let quoteView = loadQuoteView()
        
        /// This exception is normal if the tweet was deleted or hidden.
        guard let quotedTweet = realm.tweet(id: quoting) else {
            TableLog.warning("Missing reference to quoted tweet with ID \(quoting)")
            quoteView.configure(quoted: .unavailable(quoting), requester: requester)
            return
        }
        guard let quotedUser = realm.user(id: quotedTweet.authorID) else {
            TableLog.error("Could not find user by ID \(quotedTweet.authorID)")
            assert(false)
            quoteView.configure(quoted: nil, requester: requester)
            return
        }
        
        quoteView.configure(quoted: .available(tweet: quotedTweet, author: quotedUser), requester: requester)
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
extension TweetCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        open(url: URL)
        return false
    }
}

extension TweetCell {
    @MainActor
    func loadQuoteView() -> QuoteView {
        if let existing = quoteView { return existing }
        
        let quoteView: QuoteView = .init()
        
        /// Insert below media.
        if let index = stackView.arrangedSubviews.firstIndex(where: { subview in
            subview === albumVC.view
        }) {
            stackView.insertSubview(quoteView, at: index)
        } else {
            stackView.addArrangedSubview(quoteView)
            TableLog.error("Could not find index to insert!")
            assert(false)
        }
        
        /// Configure quotation view.
        quoteView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            quoteView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            quoteView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
        ])
        
        self.quoteView = quoteView
        return quoteView
    }
}
