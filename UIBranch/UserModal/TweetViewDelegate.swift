//
//  TweetViewDelegate.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 4/1/22.
//

import Foundation
import UIKit

protocol TweetViewDelegate {
    func open(userID: User.ID) -> Void
    func open(hashtag: String) -> Void
}

extension TweetViewDelegate {
    func open(url: URL) -> Void {
        switch url.scheme {
        case UserURL.scheme:
            open(userID: UserURL.id(from: url))
        case HashtagURL.scheme:
            open(hashtag: HashtagURL.tag(from: url))
        default:
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            } else {
                showAlert(message: "Failed to open url: \(url.absoluteString)")
            }
        }
    }
}

extension ControlledCell: TweetViewDelegate {
    func open(userID: User.ID) {
        #warning("DEBUG")
        UserFetcher.shared.intake.send(userID)
        
        let realm = try! Realm()
        guard realm.user(id: userID) != nil else {
            showAlert(message: "Could not find that user.")
            
            ModelLog.error("Could not find user with id \(userID)")
            UserFetcher.shared.intake.send(userID)
            
            return
        }
        
        let modal: UserModalViewController = .init(userID: userID)
        if let sheetController = modal.sheetPresentationController {
            sheetController.detents = [
                .medium(),
                .large(),
            ]
            sheetController.prefersGrabberVisible = true
        }
        controller.present(modal, animated: true) { }
    }
    
    func open(hashtag: String) {
        #warning("Not Implemented")
        NOT_IMPLEMENTED()
    }
}
