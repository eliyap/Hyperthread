//
//  GetHeight.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 8/12/21.
//


import UIKit
import BlackBox

/// Shorthand for obtaining window chrome dimentions in `UINavigationController`.
extension UIViewController {
    func getNavBarHeight() -> CGFloat {
        let guess: CGFloat = 50 /// An observed value.
        guard let height = navigationController?.navigationBar.frame.height else {
            /// 22.01.07: this is a common, non-problematic failure.
            Logger.general.debug("Could not determine nav bar height!", print: false, false)
            return guess
        }
        return height
    }
    
    func getStatusBarHeight() -> CGFloat {
        let guess: CGFloat = 20 /// An observed value.
        guard let height = getWindowScene()?.statusBarManager?.statusBarFrame.height else {
            /// 22.01.07: this is a common, non-problematic failure.
            Logger.general.debug("Could not determine status bar height!", print: false, false)
            return guess
        }
        return height
    }
}
