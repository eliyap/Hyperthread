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
    
    public func configure(quoted: OptionalTweet?) -> Void {
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
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
