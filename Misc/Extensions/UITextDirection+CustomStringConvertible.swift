//
//  UITextDirection+CustomStringConvertible.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 28/3/22.
//

import UIKit

extension UITextDirection: CustomStringConvertible {
    public var description: String {
        switch rawValue {
        case UITextStorageDirection.forward.rawValue:
            return "forward"
        case UITextStorageDirection.backward.rawValue:
            return "backward"
        case UITextLayoutDirection.left.rawValue:
            return "left"
        case UITextLayoutDirection.right.rawValue:
            return "right"
        case UITextLayoutDirection.up.rawValue:
            return "up"
        case UITextLayoutDirection.down.rawValue:
            return "down"
        default:
            return "unknown"
        }
    }
}
