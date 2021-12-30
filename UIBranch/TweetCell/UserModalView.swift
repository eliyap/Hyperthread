//
//  UserModalView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 29/12/21.
//

import Foundation
import UIKit
import RealmSwift

final class FollowingLine: UIStackView { 

    private let followingLabel: UILabel
    private let followingButton: UIButton

    /// In future, localize these strings.
    private let followingText = "Following"
    private let followingButtonText = "Unfollow"
    private let notFollowingText = "Not following"
    private let notFollowingButtonText = "Follow"

    init() {
        self.followingLabel = .init()
        self.followingButton = .init()
        super.init(frame: .zero)
        axis = .horizontal
        
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#warning("View Incomplete")
final class UserModalViewController: UIViewController {
    /**
    set up stack view, pin constraints,
    add username and handle label view, check for text scaling
    add following / not following button,
    hook up to realm stuff.
    */

    private let stackView: UIStackView
    
    private let nameLabel: UILabel
    private let handleLabel: UILabel
    private let followingLabel: UILabel
    private let followingButton: UIButton

    #warning("TODO: add profile view")
    
    private let userID: User.ID
    
    private let token: NotificationToken? = nil
    
    init(userID: User.ID) {
        self.userID = userID
        self.stackView = .init()
        self.nameLabel = .init()
        self.handleLabel = .init()
        self.followingLabel = .init()
        self.followingButton = .init(configuration: .filled(), primaryAction: nil)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .automatic
        view.backgroundColor = .systemBackground
        
        /// Configure `UIStackView`.
        view.addSubview(stackView)
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(handleLabel)
        stackView.addArrangedSubview(followingButton)
        followingButton.setTitle("Following?", for: .normal)

        configure(userID: userID)
    }
    
    private func configure(userID: User.ID) -> Void {
        let realm = try! Realm()
        guard let user = realm.user(id: userID) else {
            TableLog.error("Could not find user with \(userID)")
            assert(false)
            return
        }
        
        nameLabel.text = user.name
        handleLabel.text = user.handle
        if user.following {
            followingButton.setTitle("Following", for: .normal)
        } else {
            followingButton.setTitle("Follow", for: .normal)
        }
    }
    
    @objc
    private func followingButtonOnTap() -> Void {
        Swift.debugPrint("Tap!")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        token?.invalidate()
    }
}
