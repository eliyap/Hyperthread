//
//  RetweetView.swift
//  Hyperthread
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
        
        let retweeters = realm.objects(Tweet.self)
            .filter("\(Tweet.retweetingPropertyName) == '\(tweet.id)'")
            .map(\.authorID)
        retweeters.forEach { userID in
            let user = realm.user(id: userID)!
            let label = IconView(sfSymbol: RetweetSymbol.name, symbolConfig: RetweetSymbol.config)
            label.setText(to: "@" + user.handle)
            retweetLabels.append(label)
            addArrangedSubview(label)
        }
    }
}
