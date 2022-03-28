//
//  LiveString.Index.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 28/3/22.
//

import Foundation

extension LiveString {
    /// 2D index into a `LiveString`.
    struct Index {
        /// The "line" on which the index is located.
        /// Min: 0
        /// Max: lines.count - 1
        let row: Int
        
        /// The "column" on which the index is located.
        let column: String.Index
        
        public static let invalid: Self = .init(row: NSNotFound, column: "".startIndex)
    }
}

extension LiveString.Index: Comparable {
    static func <(lhs: Self, rhs: Self) -> Bool {
        if (lhs.row == rhs.row) {
            return lhs.column < rhs.column
        } else {
            return lhs.row < rhs.row
        }
    }
}

extension LiveString.Index: CustomStringConvertible {
    var description: String {
        "(row: \(row), index \(column.encodedOffset))"
    }
}
