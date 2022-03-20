//
//  UserView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 13/11/21.
//

import UIKit
import RealmSwift
import Twig

final class UserView: UIStackView {
    
    private let vStack: UIStackView
    private let profileImage: ProfileImageView
    private let nameLabel: UILabel
    private let handleLabel: UILabel
    fileprivate let _spacing: CGFloat = 5

    /// Combine communication line.
    weak var line: CellEventLine? = nil
    
    /// Track the current User ID.
    private var userID: User.ID? = nil
    
    init(line: CellEventLine? = nil, constrainLines: Bool = true) {
        self.vStack = .init()
        self.profileImage = .init()
        self.nameLabel = .init()
        self.handleLabel = .init()
        self.line = line
        super.init(frame: .zero)
        axis = .horizontal
        alignment = .firstBaseline
        spacing = _spacing

        /// Construct view hierarchy.
        addArrangedSubview(profileImage)
        addArrangedSubview(vStack)
        vStack.axis = .vertical
        vStack.alignment = .leading
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.spacing = .zero
        vStack.addArrangedSubview(nameLabel)
        vStack.addArrangedSubview(handleLabel)
        
        nameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        nameLabel.adjustsFontForContentSizeCategory = true
        
        handleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        handleLabel.adjustsFontForContentSizeCategory = true
        handleLabel.textColor = .secondaryLabel
        
        /// Compress Twitter handle, then long username, but never the symbol!
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        handleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        if constrainLines == false {
            /// Permit name and handle to wrap multiple lines.
            nameLabel.numberOfLines = 0
            handleLabel.numberOfLines = 0
        }
        
        constrain()
    }
    
    func constrain() -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            profileImage.heightAnchor.constraint(equalTo: heightAnchor),
            vStack.heightAnchor.constraint(equalTo: heightAnchor),
        ])
        
        /// Combats the profile image "as short as possible" preference, avoiding a "crushed" view.
        vStack.setContentCompressionResistancePriority(.required, for: .vertical)
        nameLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        handleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    public func configure(user: User) {
        self.userID = user.id
        
        profileImage.configure(user: user)
        
        nameLabel.text = user.name
        handleLabel.text = "@" + user.handle
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        /// Don't count as a cell touch.
        // super.touchesEnded(touches, with: event)
        
        guard let userID = userID else {
            NetLog.error("Missing User ID on username tap!")
            assert(false)
            return
        }

        line?.events.send(.usernameTouch(userID))
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
