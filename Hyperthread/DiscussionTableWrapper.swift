//
//  DiscussionTableWrapper.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 31/1/22.
//

import Foundation
import UIKit

final class DiscussionTableWrapper: UIViewController, Sendable {
    
    private let wrapped: DiscussionTable
    private let topBar: TableTopBar
    public let loadingCarrier: UserMessageCarrier = .init()
    
    /// Expose underlying discussion to allow `SplitViewController` to decide how to collapse.
    public var discussion: Discussion? {
        wrapped.discussion
    }
    
    @MainActor
    init() {
        topBar = .init(loadingCarrier: loadingCarrier)
        wrapped = .init(loadingCarrier: loadingCarrier)
        super.init(nibName: nil, bundle: nil)
        adopt(wrapped)
        pinEdges()
        
        view.addSubview(topBar)
        topBar.constrain(to: view)
        view.bringSubviewToFront(topBar)
        
        #if DEBUG
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(debugMethod)),
        ]
        #endif
    }
    
    #if DEBUG
    @objc
    func debugMethod() {
        // loading method
        Task { @MainActor in
            await loadingCarrier.send(.init(category: .loading, duration: .interval(1.0)))
        }
    }
    #endif
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        /// Solves issue observed 22.01.31 where iPad resizing failed.
        pinEdges()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        /// Solves issue observed 22.01.31 where iPad resizing failed.
        pinEdges()
    }
    
    @MainActor
    private func pinEdges() -> Void {
        /// Pin edges.
        wrapped.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            wrapped.view.topAnchor.constraint(equalTo: view.topAnchor),
            wrapped.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            wrapped.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            wrapped.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("No.")
    }
}

extension DiscussionTableWrapper: SplitDelegate {
    func present(_ discussion: Discussion) -> Void {
        /// Forward arguments.
        wrapped.present(discussion)
        
        /// Needs to be kept in front of newly made `UITableView`.
        view.bringSubviewToFront(topBar)
    }
}

/// - Note: for goodness sakes, name this better.
protocol DiscusssionRequestable: AnyObject {
    func requestDiscussionFromTweetID(_ tweetID: Tweet.ID)
}

extension DiscussionTableWrapper: DiscusssionRequestable {
    func requestDiscussionFromTweetID(_ tweetID: Tweet.ID) {
        /// Implement simple error handling for the request.
        do {
            try presentFetchedDiscussion(tweetID: tweetID)
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
}
