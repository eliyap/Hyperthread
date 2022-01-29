//
//  FollowingLine.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 29/12/21.
//

import Foundation
import UIKit
import RealmSwift
import Twig

final class FollowingLine: UIStackView { 

    public static let inset = CardTeaserCell.borderInset
    
    private let followingLabel: UILabel
    private let followingButton: FollowButton

    /// In future, localize these strings.
    private let followingText = "Following"
    private let notFollowingText = "Not following"
    
    /// Tracks user state.
    private var userID: User.ID
    private var following: Bool
    
    public static let font: UIFont = .preferredFont(forTextStyle: .body)
    
    init(user: User) {
        self.userID = user.id
        self.following = user.following
        
        self.followingLabel = .init()
        self.followingButton = FollowButton()
        
        super.init(frame: .zero)
        axis = .horizontal
        translatesAutoresizingMaskIntoConstraints = false
        spacing = UIStackView.spacingUseSystem
        backgroundColor = .card
        
        /// Inset subviews from edges.
        /// Source: https://useyourloaf.com/blog/adding-padding-to-a-stack-view/
        isLayoutMarginsRelativeArrangement = true
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: Self.inset, leading: Self.inset, bottom: Self.inset, trailing: Self.inset)
        
        layer.cornerRadius = Self.inset * 2
        layer.borderWidth = 1.00
        layer.borderColor = UIColor.secondarySystemFill.cgColor
        
        let action = UIAction(handler: onButtonTap(_:))
        followingButton.addAction(action, for: .touchUpInside)
        
        followingLabel.font = Self.font
        
        addArrangedSubview(followingLabel)
        addArrangedSubview(followingButton)
        
    }
    
    private func onButtonTap(_: UIAction) -> Void {
        guard let credentials = Auth.shared.credentials else {
            TableLog.error("Could not load credentials in user modal view!")
            assert(false)
            showAlert(message: "Failed to send follow request")
            return
        }

        guard userID != "\(credentials.user_id)" else {
            assert(false, "Cannot follow self!")
            return
        }
        
        Task {
            followingButton.isEnabled = false
            followingButton.loading.startAnimating()
            
            if following {
                let success = await Self.performUnfollow(userID: userID, credentials: credentials)
                if success {
                    onUnfollow(userIDs: [userID])
                    followingButton.isEnabled = true
                    followingButton.loading.stopAnimating()
                }
            } else {
                let success = await Self.performFollow(userID: userID, credentials: credentials)
                if success {
                    onFollow(userIDs: [userID])
                    followingButton.isEnabled = true
                    followingButton.loading.stopAnimating()
                }
            }
        }
    }
    
    /// Perform network task, and validate result.
    /// Return value indicates success.
    private static func performFollow(userID: User.ID, credentials: OAuthCredentials) async -> Bool {
        var result: FollowingRequestResult
        do {
            result = try await follow(userID: userID, credentials: credentials)
        } catch {
            NetLog.error("Follow request failed with error \(error)")
            showAlert(message: "Failed to follow user.")
            return false
        }
        
        guard result.following else {
            if result.pending_follow {
                showAlert(title: "Protected User", message: "User may approve follow request. Please check back later!")
                return true
            } else {
                NetLog.error("Illegal response from follow endpoint: \(result)")
                showAlert(message: "Failed to follow user.")
                return false
            }
        }
        return true
    }
    
    /// - Returns: whether the request completed successfully.
    private static func performUnfollow(userID: User.ID, credentials: OAuthCredentials) async -> Bool {
        var result: Bool
        do {
            result = try await unfollow(userID: userID, credentials: credentials)
        } catch {
            NetLog.error("Unfollow request failed with error \(error)")
            showAlert(message: "Failed to unfollow user.")
            return false
        }
        
        guard result == false else {
            NetLog.error("Illegal response from follow endpoint: \(result)")
            showAlert(message: "Failed to follow user.")
            return false
        }
        
        return true
    }
    
    func configure(user: User) -> Void {
        self.userID = user.id
        self.following = user.following
        
        /// Look up full user object.
        let realm = makeRealm()
        guard let user = realm.user(id: userID) else {
            TableLog.error("Could not find user with id \(userID)")
            showAlert(message: "Could not find user")
            return
        }
        
        if following {
            followingLabel.text = followingText
            followingButton.configure(following: true)
        } else {
            followingLabel.text = notFollowingText
            followingButton.configure(following: false)
        }
        
        /// Do not allow the user to interact with themselves, or they might go blind.
        if user.id == "\(Auth.shared.credentials?.user_id ?? .zero)" {
            isHidden = true
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class FollowButton: UIButton {
    
    private let stackView: UIStackView = .init()
    private let label: UILabel = .init()
    public let loading = UIActivityIndicatorView()
    
    init() {
        super.init(frame: .zero)
        layer.cornerCurve = .continuous
        layer.cornerRadius = FollowingLine.inset
        
        /// Set up `UIStackView`.
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.isUserInteractionEnabled = false /// Stops view from eating touches.
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: FollowingLine.inset),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -FollowingLine.inset),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: FollowingLine.inset),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -FollowingLine.inset),
        ])
        
        stackView.addArrangedSubview(label)
        label.text = "TEST"
        
        stackView.addArrangedSubview(loading)
        loading.hidesWhenStopped = true
    }
    
    public func configure(following: Bool) -> Void {
        if following {
            backgroundColor = .systemGray3
            label.attributedText = .init(string: "Unfollow", attributes: .init([.font: FollowingLine.font]))
        } else {
            backgroundColor = .systemBlue
            label.attributedText = .init(string: "Follow", attributes: .init([.font: FollowingLine.font, .foregroundColor: UIColor.white]))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
