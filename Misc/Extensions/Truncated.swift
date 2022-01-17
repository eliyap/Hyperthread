//
//  Truncated.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 16/1/22.
//

import Foundation

extension Collection where Element: CustomDebugStringConvertible, Index: BinaryInteger {
    /// Truncate long lists beyond `max` elements.
    /// Useful for printing the contents of potentially large arrays.
    func truncated(_ max: Index) -> String {
        if count <= max {
            return "\(self)"
        } else {
            return "\(self[..<max]), etc."
        }
    }
}
