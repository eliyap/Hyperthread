//
//  UserModalViewController.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 4/1/22.
//

import Foundation
import UIKit
import RealmSwift

final class UserModalViewController: UIViewController {
    
    public static let inset = CardTeaserCell.borderInset
    
    /// Component Views.
    private let doneBtn: UIButton
    private let stackView: UIStackView
    private let userView: UserView = .init(line: nil, constrainLines: false)
    private let followingLine: FollowingLine
    private let spacer: UIView

    private var token: NotificationToken? = nil
    
    init(user: User) {
        self.doneBtn = .init(configuration: .plain(), primaryAction: nil)
        self.stackView = .init()
        self.followingLine = .init(user: user)
        self.spacer = .init()
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .automatic
        view.backgroundColor = .systemBackground
        
        /// Configure `UIStackView`.
        view.addSubview(stackView)
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Self.inset
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.addArrangedSubview(doneBtn)
        stackView.addArrangedSubview(userView)
        stackView.addArrangedSubview(followingLine)
        stackView.addArrangedSubview(spacer)
        
        doneBtn.setTitle("Done", for: .normal)
        doneBtn.addAction(UIAction(handler: { [weak self] action in
            self?.dismiss(animated: true)
        }), for: .touchUpInside)
        
        configure(user: user)
        registerToken(user: user)
        
        constrain()
    }
    
    private func constrain() -> Void {
        /// Inset edges.
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Self.inset),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Self.inset),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Self.inset),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Self.inset),
        ])
        
        /// Make user view "as short as possible".
        let shortSqueeze = userView.heightAnchor.constraint(equalToConstant: .zero)
        shortSqueeze.priority = .defaultLow
        shortSqueeze.isActive = true
        
        doneBtn.contentHorizontalAlignment = .trailing
        NSLayoutConstraint.activate([
            doneBtn.widthAnchor.constraint(equalTo: stackView.widthAnchor),
        ])
    }
    
    private func registerToken(user: User) -> Void {
        /// Kill old token, just in case.
        token?.invalidate()
        
        /// Bind id locally, to prevent threading mistakes with Realm.
        let userID = user.id
        
        token = user.observe { [weak self] change in
            switch change {
            case .change(_, let properties):
                /// Perform user lookup to update object.
                /// Look up full user object.
                let realm = makeRealm()
                guard let user = realm.user(id: userID) else {
                    TableLog.error("Could not find user with id \(userID)")
                    showAlert(message: "Could not find user")
                    return
                }
                
                self?.followingLine.configure(user: user)
            
            case .error(let error):
                TableLog.error("Key Path Listenener Error: \(error)")
                assert(false)
            
            case .deleted:
                TableLog.error("User with id \(userID) deleted!")
                assert(false)
            }
        }
    }
    
    private func configure(user: User) -> Void {
        userView.configure(user: user)
        followingLine.configure(user: user)
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
