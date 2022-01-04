//
//  UserModalViewController.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 4/1/22.
//

import Foundation
import UIKit
import RealmSwift

final class UserModalViewController: UINavigationController {
    
    public static let inset = CardTeaserCell.borderInset
    
    /// Component Views.
    private let sheetView: UserSheetView

    init(userID: User.ID) {
        let realm = try! Realm()
        self.sheetView = .init()
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .automatic
        view.addSubview(sheetView)
        view.backgroundColor = .systemBackground
        
        guard let user = realm.user(id: userID) else {
            ModelLog.error("Could not find user with ID \(userID)")
            showAlert(message: "Could not find that user!")
            dismiss(animated: true)
            return
        }
        sheetView.configure(user: user)
        
        constrain()
    }
    
    private func constrain() -> Void {
        /// Inset edges.
        NSLayoutConstraint.activate([
            sheetView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Self.inset + navigationBar.frame.height),
            sheetView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Self.inset),
            sheetView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: Self.inset),
            sheetView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -Self.inset),
        ])
    }
    
    @objc
    private func followingButtonOnTap() -> Void {
        Swift.debugPrint("Tap!")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class UserSheetView: UIStackView {
    public static let inset = CardTeaserCell.borderInset
    
    /// Component Views.
    private let userView: UserView = .init(line: nil, constrainLines: false)
    private let followingLine: FollowingLine
    private let spacer: UIView

    private var token: NotificationToken? = nil
    
    init() {
        self.followingLine = .init()
        self.spacer = .init()
        super.init(frame: .zero)
        
        /// Configure `UIStackView`.
        axis = .vertical
        alignment = .center
        translatesAutoresizingMaskIntoConstraints = false

        addArrangedSubview(userView)
        addArrangedSubview(followingLine)
        addArrangedSubview(spacer)

        constrain()
    }
    
    private func constrain() -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        
        /// Make user view "as short as possible".
        let shortSqueeze = userView.heightAnchor.constraint(equalToConstant: .zero)
        shortSqueeze.priority = .defaultLow
        shortSqueeze.isActive = true
    }
    
    public func configure(user: User) -> Void {
        userView.configure(user: user)
        registerToken(userID: user.id)
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
    
    @objc
    private func followingButtonOnTap() -> Void {
        Swift.debugPrint("Tap!")
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        token?.invalidate()
    }
}
