//
//  ReplyView.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 13/11/21.
//

import UIKit
import RealmSwift
import Twig

final class ReplyView: UIStackView {

    let replyLabel = IconView(sfSymbol: "arrowshape.turn.up.backward.fill")
    let quoteLabel = IconView(sfSymbol: "quote.bubble.fill")

    init() {
        super.init(frame: .zero)
        axis = .vertical
        spacing = 0
        alignment = .leading
        translatesAutoresizingMaskIntoConstraints = false
        
        addArrangedSubview(replyLabel)
        addArrangedSubview(quoteLabel)

        // temp
        replyLabel.setText(to: "Reply")
        quoteLabel.setText(to: "Quote")
    }
    
    func configure(tweet: Tweet, realm: Realm) -> Void {
        if let replyingID = tweet.replying_to {
            if
                let t = realm.tweet(id: replyingID),
                let handle = realm.user(id: t.authorID)?.handle
            {
                replyLabel.setText(to: "@" + handle)
            } else {
                Swift.debugPrint("Unable to lookup replied user")
                replyLabel.setText(to: "@[ERROR]")
            }
            replyLabel.isHidden = false
        } else {
            replyLabel.isHidden = true
        }
        
        if let quotingID = tweet.quoting {
            guard
                let t = realm.tweet(id: quotingID),
                let handle = realm.user(id: t.authorID)?.handle
            else { fatalError("Unable to lookup quoted user!") }
            quoteLabel.setText(to: "@" + handle)
            quoteLabel.isHidden = false
        } else {
            quoteLabel.isHidden = true
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
