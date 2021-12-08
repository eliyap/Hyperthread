//
//  Supertall.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 7/12/21.
//

import CoreGraphics

/// A height used to request a view be "as tall as possible".
/// Using `greatestFiniteMagnitude` triggers "NSLayoutConstraint is being configured with a constant that exceeds internal limits" warning.
/// Instead, use a height far exceeding any screen-size in 2021.
extension CGFloat {
    static let superTall: CGFloat = 30000
}
