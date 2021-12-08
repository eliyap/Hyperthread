//
//  ArrowRefreshControl.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 8/12/21.
//

import UIKit

final class ArrowRefreshControl: UIRefreshControl {
    override func beginRefreshing() {
        super.beginRefreshing()
        print("Begin Refreshing!")
    }
    
    override func endRefreshing() {
        super.endRefreshing()
        print("End Refreshing!")
    }
}
