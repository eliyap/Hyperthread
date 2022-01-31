//
//  MainTableWrapper.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 18/1/22.
//

import Foundation
import UIKit
import Combine
import BlackBox

final class MainTableWrapper: UIViewController, Sendable {
    
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
    }
    #endif
    
    required init?(coder: NSCoder) {
        fatalError("No.")
    }
}

// MARK: - Tweet Lookup Support
enum TweetLookupError: Error {
    case badString
    case couldNotFindTweet
}

fileprivate extension MainTableWrapper {
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
            await loadingCarrier.send(.init(category: .loading))
            
            do {
                let discussionID = try await fetchDiscussion(tweetID: tweetID)
                
                /// - Note: Cannot add `@Sendable` into `MainActor.run` block.
                ///         We may rely on discussion lookup not failing, since indicator is non-critical.
                await loadingCarrier.send(.init(category: .loaded))
                
                try await MainActor.run {
                    guard let discussion = makeRealm().discussion(id: discussionID) else {
                        Logger.general.error("Could not locate discussion with ID \(discussionID)")
                        assert(false)
                        throw TweetLookupError.couldNotFindTweet
                    }
                    
                    splitViewController?.show(.secondary)
                    splitDelegate.present(discussion)
                }
            } catch {
                await loadingCarrier.send(.init(category: .otherError(error)))
                throw error
            }
        }
    }
}

@MainActor /// UI code.
func requestURL(completion: @escaping (String?) -> ()) -> UIAlertController {
    let alert = UIAlertController(title: "Lookup Tweet", message: "Paste Link to Tweet", preferredStyle: .alert)
    alert.addTextField { (textField) in
        textField.placeholder = "https://twitter.com/s/status/1485402219092398081"
        textField.text = ""
    }
    
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
        completion(nil)
    }))
    
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] _ in
        guard let alert = alert else {
            Logger.general.error("nil weak value in \(#function)")
            assert(false)
            
            completion(nil)
            return
        }
        guard let textField = alert.textFields?.first else {
            Logger.general.error("Failed to find text field!")
            assert(false)
            
            completion(nil)
            return
        }
        completion(textField.text)
    }))
    
    return alert
}
