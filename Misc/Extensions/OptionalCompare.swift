//
//  OptionalCompare.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 7/11/21.
//

import Foundation

/// When taking the `max` of two `Optional`s, consider `nil` to be "smaller".
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

/// When taking the `min` of two `Optional`s, consider `nil` to be "larger".
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
