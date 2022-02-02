//
//  DiscussionLoader.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 31/1/22.
//

import Foundation
import BlackBox
import UIKit

protocol DiscussionPresenter: UIViewController, Sendable {
    var loadingCarrier: UserMessageCarrier { get }
    
    @MainActor
    func present(discussion: Discussion) -> Void
}

extension MainTableWrapper: DiscussionPresenter {
    func present(discussion: Discussion) {
        splitViewController?.show(.secondary)
        splitDelegate.present(discussion)
    }
}

extension DiscussionTableWrapper: DiscussionPresenter {
    func present(discussion: Discussion) {
        let dvc = DiscussionTableWrapper()
        dvc.present(discussion)
        hasNavStack = true
        self.navigationController?.pushViewController(dvc, animated: true)
    }
}

extension DiscussionPresenter {
    /// Shared code for presenting load progress to user.
    func presentFetchedDiscussion(tweetID: Tweet.ID) -> Void {
        Task<Void, Never> {
            do {
                await loadingCarrier.send(.init(category: .loading))
                
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
                    
                    present(discussion: discussion)
                }
            } catch TweetLookupError.couldNotFindTweet {
                await showAlert( title: "Could Not Load Tweet", message: """
                    Couldn't fetch tweet.
                    It might be hidden or deleted.
                    """)
            } catch {
                await loadingCarrier.send(.init(category: .otherError(error)))
            }
        }
    }
}
