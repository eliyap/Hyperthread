//
//  CustomTextLabel+Ignored.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 27/3/22.
//

import UIKit

/// Implementations for functionality we do not support.
extension CustomTextLabel {
    // MARK: - Writing Direction Conformance
    func baseWritingDirection(for position: UITextPosition, in direction: UITextStorageDirection) -> NSWritingDirection {
        return .leftToRight
    }

    func setBaseWritingDirection(_ writingDirection: NSWritingDirection, for range: UITextRange) {
        assert(false, "Not Supported")
    }

    // MARK: - Edit Text Conformance
    func insertText(_ text: String) { assert(false, "Not Supported") }
    func deleteBackward() { assert(false, "Not Supported") }
    func replace(_ range: UITextRange, withText text: String) { assert(false, "Not Supported") }

    // MARK: - Marked Text Conformance
    func setMarkedText(_ markedText: String?, selectedRange: NSRange) { assert(false, "Not Supported") }
    func unmarkText() { assert(false, "Not Supported") }
    var markedTextStyle: [NSAttributedString.Key : Any]? {
        get { return nil }
        set(markedTextStyle) { assert(false, "Not Supported") }
    }
    var markedTextRange: UITextRange? { return nil }
}
