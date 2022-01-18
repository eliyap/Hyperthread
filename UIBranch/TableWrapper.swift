//
//  TableWrapper.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 18/1/22.
//

import Foundation
import UIKit

final class TableWrapper: UIViewController {
    
    private let wrapped: MainTable
    private let topBar: TableTopBar = .init()
    
    init(splitDelegate: SplitDelegate) {
        wrapped = .init(splitDelegate: splitDelegate)
        super.init(nibName: nil, bundle: nil)
        adopt(wrapped)
        
        view.addSubview(topBar)
        topBar.backgroundColor = .red
        topBar.constrain(to: view)
        view.bringSubviewToFront(topBar)
    }
    
    required init?(coder: NSCoder) {
        fatalError("No.")
    }
}
