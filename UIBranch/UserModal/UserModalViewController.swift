//
//  UserModalViewController.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 4/1/22.
//

import Foundation
import UIKit
import RealmSwift

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
    private let followingLine: FollowingLine

    #warning("TODO: add profile view")
    
    private let userID: User.ID
    
    private var token: NotificationToken? = nil
    
    init(userID: User.ID) {
        self.userID = userID
        self.stackView = .init()
        self.nameLabel = .init()
        self.handleLabel = .init()
        self.followingLine = .init()
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

        nameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        nameLabel.adjustsFontForContentSizeCategory = true
        stackView.addArrangedSubview(nameLabel)
        
        handleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        handleLabel.adjustsFontForContentSizeCategory = true
        handleLabel.textColor = .secondaryLabel
        stackView.addArrangedSubview(handleLabel)
        
        stackView.addArrangedSubview(followingLine)
        
        configure(userID: userID)
        registerToken(userID: userID)
    }
    
    private func registerToken(userID: User.ID) -> Void {
        token?.invalidate()
        let realm = try! Realm()
        token = realm.user(id: userID)?.observe { [weak self] change in
            switch change {
            case .change(_, let properties):
                for property in properties {
                    if property.name == User.followingPropertyName {
                        guard let following = property.newValue as? User.FollowingPropertyType else {
                            TableLog.error("Incorrect type \(type(of: property.newValue))")
                            assert(false)
                            return
                        }
                        self?.followingLine.configure(userID: userID, following: following)
                    }
                }
            case .error(let error):
                TableLog.error("Key Path Listenener Error: \(error)")
                assert(false)
            case .deleted:
                TableLog.error("User with id \(userID) deleted!")
                assert(false)
            }
        }
    }
    
    private func configure(userID: User.ID) -> Void {
        let realm = try! Realm()
        
        if let user = realm.user(id: userID) {
            nameLabel.text = user.name
            handleLabel.text = "@" + user.handle
            followingLine.configure(userID: userID, following: user.following)
        } else {
            TableLog.error("Could not find user with \(userID)")
            nameLabel.text = "⚠️ UNKNOWN USER"
            handleLabel.text = "@⚠️"
            followingLine.configure(userID: userID, following: false)
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