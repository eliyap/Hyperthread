//
//  TweetViewDelegate.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 4/1/22.
//

import Foundation
import UIKit
import RealmSwift

protocol TweetViewDelegate {
    func open(userID: User.ID) -> Void
    func open(hashtag: String) -> Void
}

extension TweetViewDelegate {
    @MainActor /// Uses `@MainActor` `UIApplication.shared`.
    func open(url: URL) -> Void {
        switch url.scheme {
        case UserURL.scheme:
            open(userID: UserURL.id(from: url))
        case HashtagURL.scheme:
            open(hashtag: HashtagURL.tag(from: url))
        default:
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url) { success in
                    if success == false {
                        showAlert(message: "Failed to open url: \(url.absoluteString)")
                    }
                }
            } else {
                showAlert(message: "Failed to open url: \(url.absoluteString)")
            }
        }
    }
}

extension ControlledCell: TweetViewDelegate, Sendable {
    func open(userID: User.ID) {
        Task {
            /// Check if user is present.
            let realm = makeRealm()
            if realm.user(id: userID) == nil {
                ModelLog.error("Could not find user with id \(userID)")
                
                /// If not, delay presentation until they've been fetched.
                /// - Note: if frequent, we may wish to add a `UIActivityIndicator`.
                await fetchAndStoreUsers(ids: [userID])
            }
            
            guard let user = realm.user(id: userID) else {
                ModelLog.error("Could not find user with ID \(userID)")
                showAlert(message: "Could not find that user!")
                return
            }
            
            let modal: UserModalViewController = .init(user: user)
            if let sheetController = modal.sheetPresentationController {
                sheetController.detents = [
                    .medium(),
                    .large(),
                ]
                sheetController.prefersGrabberVisible = true
            }
            controller.present(modal, animated: true) { }
        }
    }
    
    func open(hashtag: String) {
        #warning("Not Implemented")
        NOT_IMPLEMENTED()
    }
}
