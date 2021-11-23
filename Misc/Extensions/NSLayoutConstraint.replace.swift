//
//  NSLayoutConstraint.replace.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 23/11/21.
//

import UIKit

/**
 Replace a named constraint with a new value,
 by deactivating the original, overwriting it, then activating the new constraint.
 This specific ordering avoids an "Unable to simultaneously satisfy constraints." warning.
 */
func replace<Object: AnyObject>(
    object: Object,
    on keyPath: ReferenceWritableKeyPath<Object, NSLayoutConstraint>,
    with other: NSLayoutConstraint
) -> Void {
    NSLayoutConstraint.deactivate([object[keyPath: keyPath]])
    object[keyPath: keyPath] = other
    NSLayoutConstraint.activate([other])
}
