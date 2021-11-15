//
//  RetweetView.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 13/11/21.
//

import UIKit
import RealmSwift
import Twig

final class RetweetView: UIStackView {
    
    var retweetLabels: [IconView] = []

    init() {
        super.init(frame: .zero)
        axis = .vertical
        alignment = .leading
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(tweet: Tweet, realm: Realm) {
        /// Clear existing labels.
        retweetLabels.forEach {
            removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        retweetLabels = []
        
        tweet.retweetedBy.forEach { user in
            let label = IconView(sfSymbol: RetweetSymbol.name, config: RetweetSymbol.config)
            label.setText(to: "@" + user.handle)
            retweetLabels.append(label)
            addArrangedSubview(label)
        }
    }
}
