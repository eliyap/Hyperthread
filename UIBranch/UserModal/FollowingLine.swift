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
    private let notFollowingText = "Not following"
    
    private var userID: User.ID? = nil
    
    private var followingConfig: UIButton.Configuration
    private var notFollowingConfig: UIButton.Configuration
    private static let font: UIFont = .preferredFont(forTextStyle: .body)
    
    init() {
        self.followingLabel = .init()
        self.followingConfig = Self.makeFollowingConfig()
        self.notFollowingConfig = Self.makeNotFollowingConfig()
        self.followingButton = .init(configuration: followingConfig, primaryAction: nil)
        
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
        
        followingLabel.font = Self.font
        
        addArrangedSubview(followingLabel)
        addArrangedSubview(followingButton)
    }
    
    func configure(userID: User.ID, following: User.FollowingPropertyType) -> Void {
        self.userID = userID
        if following {
            followingLabel.text = followingText
            followingButton.configuration = followingConfig
        } else {
            followingLabel.text = notFollowingText
            followingButton.configuration = notFollowingConfig
        }
    }
    
    private static func makeFollowingConfig() -> UIButton.Configuration {
        var config: UIButton.Configuration = .filled()
        config.cornerStyle = .fixed
        config.background.cornerRadius = Self.inset
        config.attributedTitle = .init("Unfollow", attributes: .init([.font: Self.font]))
        return config
    }
    
    private static func makeNotFollowingConfig() -> UIButton.Configuration {
        var config: UIButton.Configuration = .gray()
        config.cornerStyle = .fixed
        config.background.cornerRadius = Self.inset
        config.attributedTitle = .init("Follow", attributes: .init([.font: Self.font]))
        return config
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

