//
//  UserView.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 13/11/21.
//

import UIKit
import RealmSwift
import Twig

final class UserView: UIStackView {
    
    private let nameLabel = UILabel()
    private let handleLabel = UILabel()
    private let timestampLabel = UILabel()
    fileprivate let _spacing: CGFloat = 5

    init() {
        super.init(frame: .zero)
        axis = .horizontal
        alignment = .firstBaseline
        spacing = _spacing

        translatesAutoresizingMaskIntoConstraints = false
        
        addArrangedSubview(nameLabel)
        addArrangedSubview(handleLabel)
        addArrangedSubview(timestampLabel)

        nameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        nameLabel.adjustsFontForContentSizeCategory = true
        
        handleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        handleLabel.adjustsFontForContentSizeCategory = true
        handleLabel.textColor = .secondaryLabel

        timestampLabel.adjustsFontForContentSizeCategory = true
        timestampLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        timestampLabel.textColor = .secondaryLabel
        
        /// Allow handle to be truncated if space is insufficient.
        /// We want this to be truncated before the username is.
        handleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    public func configure(user: User, timestamp: Date) {
        nameLabel.text = user.name
        handleLabel.text = "@" + user.handle
        timestampLabel.text = DateFormatter.localizedString(from: timestamp, dateStyle: .short, timeStyle: .short)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
