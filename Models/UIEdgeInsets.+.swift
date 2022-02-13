//
//  UIEdgeInsets.+.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 31/1/22.
//

import UIKit

extension UIEdgeInsets {
    static func +(lhs: Self, rhs: Self) -> Self {
        .init(top: lhs.top + rhs.top, left: lhs.left + rhs.left, bottom: lhs.bottom + rhs.bottom, right: lhs.right + rhs.right)
    }
}
