//
//  NSLayoutConstraint.replace.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 23/11/21.
//

import UIKit

/**
 Replace a named constraint with a new value,
 by deactivating the original, overwriting it, then activating the new constraint.
 This specific ordering avoids an "Unable to simultaneously satisfy constraints." warning.
 */
@MainActor /// UI code.
func replace<Object: AnyObject>(
    object: Object,
    on keyPath: ReferenceWritableKeyPath<Object, NSLayoutConstraint>,
    with other: NSLayoutConstraint
) -> Void {
    NSLayoutConstraint.deactivate([object[keyPath: keyPath]])
    object[keyPath: keyPath] = other
    NSLayoutConstraint.activate([other])
}

/// Replace named optional constraint with a new value.
@MainActor /// UI code.
func replace<Object: AnyObject>(
    object: Object,
    on keyPath: ReferenceWritableKeyPath<Object, NSLayoutConstraint?>,
    with other: NSLayoutConstraint?
) -> Void {
    object[keyPath: keyPath]?.isActive = false
    object[keyPath: keyPath] = other
    other?.isActive = true
}
