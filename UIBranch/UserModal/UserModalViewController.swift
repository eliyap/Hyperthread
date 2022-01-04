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

    private let userID: User.ID
    
    private var token: NotificationToken? = nil
    
    init(userID: User.ID) {
        self.doneBtn = .init(configuration: .plain(), primaryAction: nil)
        self.userID = userID
        self.stackView = .init()
        self.followingLine = .init()
        self.spacer = .init()
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .automatic
        view.backgroundColor = .systemBackground
        
        /// Configure `UIStackView`.
        view.addSubview(stackView)
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false

        stackView.addArrangedSubview(doneBtn)
        stackView.addArrangedSubview(userView)
        stackView.addArrangedSubview(followingLine)
        stackView.addArrangedSubview(spacer)
        
        doneBtn.setTitle("Done", for: .normal)
        
        let realm = try! Realm()
        guard let user = realm.user(id: userID) else {
            ModelLog.error("Could not find user with ID \(userID)")
            showAlert(message: "Could not find that user!")
            dismiss(animated: true)
            return
        }
        configure(user: user)
        registerToken(userID: userID)
        
        constrain()
    }
    
    private func constrain() -> Void {
        /// Inset edges.
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: Self.inset),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -Self.inset),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Self.inset),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Self.inset),
        ])
        
        /// Make user view "as short as possible".
        let shortSqueeze = userView.heightAnchor.constraint(equalToConstant: .zero)
        shortSqueeze.priority = .defaultLow
        shortSqueeze.isActive = true
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
    
    private func configure(user: User) -> Void {
        userView.configure(user: user)
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
