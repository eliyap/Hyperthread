//
//  QuoteView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 29/1/22.
//

import UIKit

final class QuoteView: UIView {
    
    /// Component views.
    let cardBackground: CardBackground = .init()
    let stackView: UIStackView = .init()
    let userView: UserView = .init()
    let tweetTextView: TweetTextView = .init()
    
    private let inset: CGFloat = CardTeaserCell.borderInset
    
    private weak var requester: DiscusssionRequestable?
    private var tweetID: Tweet.ID? = nil
    
    @MainActor
    init() {
        super.init(frame: .zero)
        
        addSubview(cardBackground)
        cardBackground.constrain(toView: self)
        
        addSubview(stackView)
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: inset * 2),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset * 2),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset * 2),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -inset * 2),
        ])
        
        stackView.addArrangedSubview(userView)
        stackView.addArrangedSubview(tweetTextView)
    }
    
    public func configure(
        quoted: OptionalTweet?,
        requester: DiscusssionRequestable?
    ) -> Void {
        self.requester = requester
        self.tweetID = quoted?.id
        
        switch quoted {
        case .none:
            isHidden = true
            userView.isHidden = true
            tweetTextView.isHidden = true
            
        case .unavailable(_):
            isHidden = false
            userView.isHidden = true
            tweetTextView.isHidden = false
            
            tweetTextView.attributedText = Tweet.notAvailableAttributedString
        
        case .available(let tweet, let author):
            isHidden = false
            userView.isHidden = false
            tweetTextView.isHidden = false
            
            userView.configure(user: author)
            tweetTextView.attributedText = tweet.attributedString
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let tweetID = tweetID else {
            TableLog.error("Tapped on quote with no ID!")
            assert(false)
            return
        }

        requester?.requestDiscussionFromTweetID(tweetID)
    }
    
    /// From `touchesEnded`:
    /// Docs: https://developer.apple.com/documentation/uikit/uiresponder/1621084-touchesended
    /// > If you override this method without calling `super` (a common use pattern),
    /// > you must also override the other methods for handling touch events, even if your implementations do nothing.
    ///
    /// - Note: failing to include these methods caused `tableView(_:, didSelectRowAt:)` to return wrong values.
    override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) { }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
