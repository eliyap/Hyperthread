//
//  FollowingLine.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 29/12/21.
//

import Foundation
import UIKit
import RealmSwift

final class FollowingLine: UIStackView { 

    public static let inset = CardTeaserCell.borderInset
    
    private let followingLabel: UILabel
    private let followingButton: UIButton

    /// In future, localize these strings.
    private let followingText = "Following"
    private let followingButtonText = "Unfollow"
    private let notFollowingText = "Not following"
    private let notFollowingButtonText = "Follow"

    private var userID: User.ID? = nil
    
    init() {
        self.followingLabel = .init()
        
        var buttonConfig: UIButton.Configuration = .filled()
        buttonConfig.cornerStyle = .fixed
        buttonConfig.background.cornerRadius = Self.inset
        self.followingButton = .init(configuration: buttonConfig, primaryAction: nil)
        
        super.init(frame: .zero)
        axis = .horizontal
        translatesAutoresizingMaskIntoConstraints = false
        spacing = UIStackView.spacingUseSystem
        
        /// Inset subviews from edges.
        /// Source: https://useyourloaf.com/blog/adding-padding-to-a-stack-view/
        isLayoutMarginsRelativeArrangement = true
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: Self.inset, leading: Self.inset, bottom: Self.inset, trailing: Self.inset)
        
        layer.cornerRadius = Self.inset * 2
        layer.borderWidth = 1.00
        layer.borderColor = UIColor.secondarySystemFill.cgColor
        
        let action = UIAction(handler: { [weak self] action in
            let realm = try! Realm()
            guard let userID = self?.userID else {
                assert(false, "Missing userID!")
                return
            }
            guard let user = realm.user(id: userID) else {
                TableLog.error("Missing user with id \(userID)")
                assert(false)
                return
            }
            do {
                try realm.write { user.following.toggle() }
            } catch {
                TableLog.error("Error in editing following: \(error)")
                assert(false)
                return
            }

        })
        followingButton.addAction(action, for: .touchUpInside)
        
        addArrangedSubview(followingLabel)
        addArrangedSubview(followingButton)
    }
    
    func configure(userID: User.ID, following: User.FollowingPropertyType) -> Void {
        self.userID = userID
        if following {
            followingLabel.text = followingText
            followingButton.setTitle(followingButtonText, for: .normal)
            followingButton.configuration = .gray()
        } else {
            followingLabel.text = notFollowingText
            followingButton.setTitle(notFollowingButtonText, for: .normal)
            followingButton.configuration = .filled()
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

