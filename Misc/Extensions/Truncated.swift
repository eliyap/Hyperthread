//
//  Truncated.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 16/1/22.
//

import Foundation

extension Collection where Element: CustomDebugStringConvertible, Index: BinaryInteger {
    /// Truncate long lists after `max` elements.
    func truncated(_ max: Index) -> String {
        if count <= max {
            return "\(self)"
        } else {
            return "\(self[..<max]), etc."
        }
    }
}
