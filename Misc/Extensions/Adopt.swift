//
//  Adopt.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 7/11/21.
//

import UIKit

extension UIViewController {
    /// Convenience method for adding a subview to the view hierarchy.
    /// - Warning: `subviewIndex` is **not** checked for validity.
    func adopt(_ child: UIViewController, subviewIndex: Int? = nil) {
        addChild(child)
        child.view.frame = view.frame
        if let subviewIndex = subviewIndex {
            view.insertSubview(child.view, at: subviewIndex)
        } else {
            view.addSubview(child.view)
        }
        child.didMove(toParent: self)
    }
}
