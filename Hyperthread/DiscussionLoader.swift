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
