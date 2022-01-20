//
//  TableWrapper.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 18/1/22.
//

import Foundation
import UIKit
import Combine

final class TableWrapper: UIViewController {
    
    private let wrapped: MainTable
    private let topBar: TableTopBar
    private let loadingConduit: UserMessageConduit = .init()
    
    init(splitDelegate: SplitDelegate) {
        topBar = .init(loadingConduit: loadingConduit)
        wrapped = .init(splitDelegate: splitDelegate, loadingConduit: loadingConduit)
        super.init(nibName: nil, bundle: nil)
        adopt(wrapped)
        
        view.addSubview(topBar)
        topBar.constrain(to: view)
        view.bringSubviewToFront(topBar)
        
        #if DEBUG
        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(debugMethod)),
        ]
        #endif
    }
    
    #if DEBUG
    @objc
    func debugMethod() {
        loadingConduit.send(.init(category: .loading, duration: .interval(1.0)))
    }
    #endif
    
    required init?(coder: NSCoder) {
        fatalError("No.")
    }
}
