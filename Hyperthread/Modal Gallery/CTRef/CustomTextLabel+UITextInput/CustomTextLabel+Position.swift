//
//  CustomTextLabel+Position.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 27/3/22.
//

import UIKit

/// Functions relating to internally referenced text positions.
extension CustomTextLabel {
    func text(in range: UITextRange) -> String? {
        guard
            let rangeStart = range.start as? CustomTextPosition,
            let rangeEnd = range.end as? CustomTextPosition
        else {
            assert(false, "Unexpected type")
            return nil
        }
        
        let start = max(rangeStart.offset, 0)
        let end = min(labelText.count, rangeEnd.offset)
        var length = end - start
        length = max(length, 0)
        
        guard
            start < labelText.count,
            let subrange = Range(NSRange(location: start, length: length), in: labelText)
        else {
            return nil
        }
        
        return String(labelText[subrange])
    }
    
    var selectedTextRange: UITextRange? {
        get {
            currentSelectedTextRange
        }
        set(selectedTextRange) {
            currentSelectedTextRange = selectedTextRange
        }
    }
    
    var beginningOfDocument: UITextPosition {
        CustomTextPosition(offset: 0)
    }
    
    var endOfDocument: UITextPosition {
        CustomTextPosition(offset: labelText.count)
    }
    
    func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        guard let fromPosition = fromPosition as? CustomTextPosition, let toPosition = toPosition as? CustomTextPosition else {
            assert(false, "Unexpected type")
            return nil
        }
        return CustomTextRange(startOffset: fromPosition.offset, endOffset: toPosition.offset)
    }
    
    func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        guard let position = position as? CustomTextPosition else {
            assert(false, "Unexpected type")
            return nil
        }
        
        let proposedIndex = position.offset + offset
        
        // return nil if proposed index is out of bounds, per documentation
        guard proposedIndex >= 0 && proposedIndex <= labelText.count else {
            return nil
        }
        
        return CustomTextPosition(offset: proposedIndex)
    }
    
    func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
        guard let position = position as? CustomTextPosition else {
            assert(false, "Unexpected type")
            return nil
        }
        
        var proposedIndex: Int = position.offset
        if direction == .left {
            proposedIndex = position.offset - offset
        }
        
        if direction == .right {
            proposedIndex = position.offset + offset
        }
        
        // return nil if proposed index is out of bounds
        guard proposedIndex >= 0 && proposedIndex <= labelText.count else {
            return nil
        }
        
        return CustomTextPosition(offset: proposedIndex)
    }
    
    func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        guard
            let position = position as? CustomTextPosition,
            let other = other as? CustomTextPosition
        else {
            assert(false, "Unexpected type")
            return .orderedSame
        }
        
        if position < other {
            return .orderedAscending
        } else if position > other {
            return .orderedDescending
        } else {
            return .orderedSame
        }
    }
    
    func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
        guard
            let from = from as? CustomTextPosition,
            let toPosition = toPosition as? CustomTextPosition
        else {
            assert(false, "Unexpected type")
            return 0
        }
        
        return toPosition.offset - from.offset
    }
    
    var inputDelegate: UITextInputDelegate? {
        get {
            nil // TODO: implement
        }
        set(inputDelegate) {
            // TODO: implement
        }
    }
    
    var tokenizer: UITextInputTokenizer {
        return UITextInputStringTokenizer(textInput: self)
    }
    
    func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
        
        let isStartFirst = compare(range.start, to: range.end) == .orderedAscending
        
        switch direction {
        case .left, .up:
            return isStartFirst ? range.start : range.end
        case .right, .down:
            return isStartFirst ? range.end : range.start
        @unknown default:
            fatalError()
        }
    }
    
    func characterRange(byExtending position: UITextPosition, in direction: UITextLayoutDirection) -> UITextRange? {
        guard let position = position as? CustomTextPosition else {
            return nil
        }
        
        switch direction {
        case .left, .up:
            return CustomTextRange(startOffset: 0, endOffset: position.offset)
        case .right, .down:
            return CustomTextRange(startOffset: position.offset, endOffset: labelText.count)
        @unknown default:
            fatalError()
        }
    }
}
