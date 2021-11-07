//
//  OptionalCompare.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 7/11/21.
//

import Foundation

/// Ignore nil value in `max`.
func max<T: Comparable>(_ lhs: T?, _ rhs: T?) -> T? {
    switch (lhs, rhs) {
    case (.some(let lhs), .some(let rhs)):
        return Swift.max(lhs, rhs)
    case (.some(let lhs), .none):
        return lhs
    case (.none, .some(let rhs)):
        return rhs
    case (.none, .none):
        return nil
    }
}

/// Ignore nil value in `min`.
func min<T: Comparable>(_ lhs: T?, _ rhs: T?) -> T? {
    switch (lhs, rhs) {
    case (.some(let lhs), .some(let rhs)):
        return Swift.min(lhs, rhs)
    case (.some(let lhs), .none):
        return lhs
    case (.none, .some(let rhs)):
        return rhs
    case (.none, .none):
        return nil
    }
}
