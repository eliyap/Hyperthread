//
//  Adopt.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 7/11/21.
//

import UIKit

extension UIViewController {
    /// Convenience method for adding a subview to the view hierarchy.
    func adopt(_ child: UIViewController) {
        addChild(child)
        child.view.frame = view.frame
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }
}
