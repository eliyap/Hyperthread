//
//  QuoteView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 29/1/22.
//

import UIKit

final class QuoteView: UIStackView {
    
    /// Component Views.
    let userView: UserView = .init()
    let tweetTextView: TweetTextView = .init()
    
    init() {
        super.init(frame: .zero)
        axis = .vertical
        alignment = .leading
        
        addArrangedSubview(userView)
        addArrangedSubview(tweetTextView)
    }
    
    public func configure(quoted: OptionalTweet?) -> Void {
        switch quoted {
        case .none:
            isHidden = true
        
        case .unavailable(_):
            #warning("TODO")
            break
        
        case .available(let tweet, let author):
            isHidden = false
            userView.configure(user: author)
            tweetTextView.attributedText = tweet.attributedString
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
