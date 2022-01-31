//
//  DiscussionTableWrapper.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 31/1/22.
//

import Foundation
import UIKit

final class DiscussionTableWrapper: UIViewController, Sendable {
    
    public let wrapped: DiscussionTable
    private let topBar: TableTopBar
    private let loadingCarrier: UserMessageCarrier = .init()
    
    @MainActor
    init() {
        topBar = .init(loadingCarrier: loadingCarrier)
        wrapped = .init(loadingCarrier: loadingCarrier)
        super.init(nibName: nil, bundle: nil)
        adopt(wrapped)
        
        view.addSubview(topBar)
        topBar.constrain(to: view)
        view.bringSubviewToFront(topBar)
    }
    
    required init?(coder: NSCoder) {
        fatalError("No.")
    }
}
