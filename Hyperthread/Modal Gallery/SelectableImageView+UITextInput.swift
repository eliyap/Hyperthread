//
//  SelectableImageView+UITextInput.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 27/3/22.
//

import UIKit
import BlackBox

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
        guard let liveTextRange = range as? LiveTextRange else {
            assert(false, "Unexpected type")
            return nil
        }
        guard
            liveTextRange.range.lowerBound >= textContents.startIndex,
            liveTextRange.range.upperBound <= textContents.endIndex
        else {
            assert(false, "Out of bounds")
            return nil
        }
        
        let sub: Substring = textContents[liveTextRange.range]
        return String(sub)
    }
    
    var selectedTextRange: UITextRange? {
        get { self.selection }
        set(selectedTextRange) {
            guard let liveTextRange = selectedTextRange as? LiveTextRange else {
                assert(false, "Unexpected type")
                self.selection = nil
            }
            self.selection = liveTextRange
        }
    }
    
    var beginningOfDocument: UITextPosition {
        return LiveTextPosition(index: textContents.startIndex)
    }
    
    var endOfDocument: UITextPosition {
        return LiveTextPosition(index: textContents.endIndex)
    }
    
    func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        guard
            let liveTextStart = fromPosition as? LiveTextPosition,
            let liveTextEnd = toPosition as? LiveTextPosition
        else {
            assert(false, "Unexpected type")
            return nil
        }
        
        /// Swap indices if needed.
        var strStart = liveTextStart.index
        var strEnd = liveTextEnd.index
        if strStart > strEnd {
            (strStart, strEnd) = (strEnd, strStart)
        }
        
        return LiveTextRange(range: strStart..<strEnd)
    }
    
    func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        guard let liveTextPosition = position as? LiveTextPosition else {
            assert(false, "Unexpected type")
            return nil
        }

        let currentOffset = textContents.distance(from: textContents.startIndex, to: liveTextPosition.index)
        let newOffset = currentOffset + offset
        guard newOffset <= textContents.count else {
            BlackBox.Logger.general.warning("Offset is out of range")
            return nil
        }
        
        let newIndex = textContents.index(textContents.startIndex, offsetBy: newOffset)
        return LiveTextPosition(index: newIndex)
    }
    
    func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
        #warning("TODO")
        return nil
    }
    
    func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        guard
            let liveTextPosition = position as? LiveTextPosition,
            let otherLiveTextPosition = other as? LiveTextPosition
        else {
            assert(false, "Unexpected type")
            return .orderedSame
        }

        if liveTextPosition.index < otherLiveTextPosition.index {
            return .orderedAscending
        } else if liveTextPosition.index > otherLiveTextPosition.index {
            return .orderedDescending
        } else {
            return .orderedSame
        }
    }
    
    func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
        guard
            let liveTextStart = from as? LiveTextPosition,
            let liveTextEnd = toPosition as? LiveTextPosition
        else {
            assert(false, "Unexpected type")
            return 0
        }
        
        let start = textContents.distance(from: textContents.startIndex, to: liveTextStart.index)
        let end = textContents.distance(from: textContents.startIndex, to: liveTextEnd.index)
        return end - start
    }
    
    var inputDelegate: UITextInputDelegate? {
        get {
            nil
        }
        set(inputDelegate) {
            /// Nothing.
        }
    }
    
    var tokenizer: UITextInputTokenizer {
        _tokenizer
    }
    
    func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
        #warning("TODO")
        return nil
    }
    
    func characterRange(byExtending position: UITextPosition, in direction: UITextLayoutDirection) -> UITextRange? {
        #warning("TODO")
        return nil
    }
    
    func firstRect(for range: UITextRange) -> CGRect {
        #warning("TODO")
        return .zero
    }
    
    func caretRect(for position: UITextPosition) -> CGRect {
        #warning("TODO")
        return .zero
    }
    
    func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        #warning("TODO")
        return []
    }
    
    func closestPosition(to point: CGPoint) -> UITextPosition? {
        #warning("TODO")
        return nil
    }
    
    func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
        #warning("TODO")
        return nil
    }
    
    func characterRange(at point: CGPoint) -> UITextRange? {
        #warning("TODO")
        return nil
    }
    
    var hasText: Bool {
        return true
    }
    
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
