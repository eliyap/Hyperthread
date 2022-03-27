//
//  SelectableImageView+UITextInput.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 27/3/22.
//

import UIKit

final class LiveTextPosition: UITextPosition {
    
    public let index: String.Index
    
    init(index: String.Index) {
        self.index = index
        super.init()
    }
}

final class LiveTextRange: UITextRange {
    public let range: Range<String.Index>
    
    override var start: LiveTextPosition {
        LiveTextPosition(index: range.lowerBound)
    }
    override var end: LiveTextPosition {
        LiveTextPosition(index: range.upperBound)
    }
    
    init(range: Range<String.Index>) {
        self.range = range
        super.init()
    }
}

extension SelectableImageView: UITextInput {
    func text(in range: UITextRange) -> String? {
        <#code#>
    }
    
    var selectedTextRange: UITextRange? {
        get {
            <#code#>
        }
        set(selectedTextRange) {
            <#code#>
        }
    }
    
    var beginningOfDocument: UITextPosition {
        <#code#>
    }
    
    var endOfDocument: UITextPosition {
        <#code#>
    }
    
    func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        <#code#>
    }
    
    func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        <#code#>
    }
    
    func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
        <#code#>
    }
    
    func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        <#code#>
    }
    
    func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
        <#code#>
    }
    
    var inputDelegate: UITextInputDelegate? {
        get {
            <#code#>
        }
        set(inputDelegate) {
            <#code#>
        }
    }
    
    var tokenizer: UITextInputTokenizer {
        <#code#>
    }
    
    func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
        <#code#>
    }
    
    func characterRange(byExtending position: UITextPosition, in direction: UITextLayoutDirection) -> UITextRange? {
        <#code#>
    }
    
    func baseWritingDirection(for position: UITextPosition, in direction: UITextStorageDirection) -> NSWritingDirection {
        <#code#>
    }
    
    func setBaseWritingDirection(_ writingDirection: NSWritingDirection, for range: UITextRange) {
        <#code#>
    }
    
    func firstRect(for range: UITextRange) -> CGRect {
        <#code#>
    }
    
    func caretRect(for position: UITextPosition) -> CGRect {
        <#code#>
    }
    
    func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        <#code#>
    }
    
    func closestPosition(to point: CGPoint) -> UITextPosition? {
        <#code#>
    }
    
    func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
        <#code#>
    }
    
    func characterRange(at point: CGPoint) -> UITextRange? {
        <#code#>
    }
    
    var hasText: Bool {
        <#code#>
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
