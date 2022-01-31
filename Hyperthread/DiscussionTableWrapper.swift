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
    private let loadingCarrier: UserMessageCarrier = .init()
    
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
    }
    
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
    }
}
