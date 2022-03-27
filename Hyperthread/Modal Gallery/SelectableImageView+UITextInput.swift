//
//  SelectableImageView+UITextInput.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 27/3/22.
//

import UIKit

extension SelectableImageView: UITextInput {
    func text(in range: UITextRange) -> String? {
        <#code#>
    }
    
    func replace(_ range: UITextRange, withText text: String) {
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
    
    var markedTextRange: UITextRange? {
        <#code#>
    }
    
    var markedTextStyle: [NSAttributedString.Key : Any]? {
        get {
            <#code#>
        }
        set(markedTextStyle) {
            <#code#>
        }
    }
    
    func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        <#code#>
    }
    
    func unmarkText() {
        <#code#>
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
    
    func insertText(_ text: String) {
        <#code#>
    }
    
    func deleteBackward() {
        <#code#>
    }
}
