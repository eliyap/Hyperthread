//
//  GetHeight.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 8/12/21.
//


import UIKit
import BlackBox

extension UIViewController {
    func getNavBarHeight() -> CGFloat {
        let guess: CGFloat = 50 /// An observed value.
        guard let height = navigationController?.navigationBar.frame.height else {
            Logger.general.warning("Could not determine nav bar height!")
            return guess
        }
        return height
    }
    
    func getStatusBarHeight() -> CGFloat {
        let guess: CGFloat = 20 /// An observed value.
        guard let height = getWindowScene()?.statusBarManager?.statusBarFrame.height else {
            Logger.general.warning("Could not determine status bar height!")
            return guess
        }
        return height
    }
}
