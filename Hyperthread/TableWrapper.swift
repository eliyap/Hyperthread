//
//  TableWrapper.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 18/1/22.
//

import Foundation
import UIKit
import Combine
import BlackBox

final class TableWrapper: UIViewController, Sendable {
    
    private let wrapped: MainTable
    private let topBar: TableTopBar
    private let loadingCarrier: UserMessageCarrier = .init()
    
    /// Object to notify when something elsewhere in the `UISplitViewController` should change.
    private weak var splitDelegate: SplitDelegate!
    
    init(splitDelegate: SplitDelegate) {
        self.splitDelegate = splitDelegate
        topBar = .init(loadingCarrier: loadingCarrier)
        wrapped = .init(splitDelegate: splitDelegate, loadingCarrier: loadingCarrier)
        super.init(nibName: nil, bundle: nil)
        adopt(wrapped)
        
        view.addSubview(topBar)
        topBar.constrain(to: view)
        view.bringSubviewToFront(topBar)
        
        let addLinkButton = UIBarButtonItem(
            title: "Add from Link",
            image: UIImage(systemName: "link.badge.plus"),
            primaryAction: UIAction(handler: { _ in
                self.promptForLink()
            }),
            menu: nil
        )
        navigationItem.leftBarButtonItems = [
            addLinkButton,
            UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(debugMethod)),
        ]

        #if DEBUG
        navigationItem.leftBarButtonItems = navigationItem.leftBarButtonItems ?? []
        + [
            UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(debugMethod)),
        ]
        #endif
    }
    
    #if DEBUG
    @objc
    func debugMethod() {
        // loading method
//        loadingConduit.send(.init(category: .loading, duration: .interval(1.0)))
        
        // present alert controller
        let alertController = requestURL(completion: { [weak self] (string: String?) in
            guard let string = string else {
                return
            }
            #warning("handle errors")
            try! self?.tryLinkRequest(string: string)
        })
        self.present(alertController, animated: true, completion: nil)
    }
    #endif
    
    
    
    required init?(coder: NSCoder) {
        fatalError("No.")
    }
}

enum TweetLookupError: Error {
    case badString
    case couldNotFindTweet
}

fileprivate extension TableWrapper {
    func promptForLink() -> Void {
        let alertController = requestURL(completion: { [weak self] (string: String?) in
            guard let string = string else {
                return
            }
            self?.handleLinkRequest(string: string)
        })
        self.present(alertController, animated: true, completion: nil)
    }
    
    func handleLinkRequest(string: String) -> Void {
        do {
            try tryLinkRequest(string: string)
        } catch TweetLookupError.badString {
            showAlert(title: "Could Not Read Link", message: "Please check the URL")
        } catch TweetLookupError.couldNotFindTweet {
            showAlert(title: "Could Not Load Tweet", message: """
                Couldn't fetch tweet.
                It might be hidden or deleted.
                """)
        } catch {
            showAlert(title: "Error", message: "Error while loading tweet.")
        }
    }
    
    func tryLinkRequest(string: String) throws -> Void {
        guard let tweetID = URL(string: string)?.lastPathComponent else {
            throw TweetLookupError.badString
        }
        
        let isDecimalDigits = CharacterSet(charactersIn: tweetID).isSubset(of: CharacterSet.decimalDigits)
        guard isDecimalDigits else {
            throw TweetLookupError.badString
        }
        
        Task {
            let discussionID = try await fetchDiscussion(tweetID: tweetID)
            try await MainActor.run {
                guard let discussion = makeRealm().discussion(id: discussionID) else {
                    Logger.general.error("Could not locate discussion with ID \(discussionID)")
                    assert(false)
                    throw TweetLookupError.couldNotFindTweet
                }
                splitViewController?.show(.secondary)
                splitDelegate.present(discussion)
            }
        }
    }
}
