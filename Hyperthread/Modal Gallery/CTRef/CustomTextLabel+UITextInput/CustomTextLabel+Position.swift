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
        
        let customRange = rangeStart.index..<rangeEnd.index
        return labelText[customRange]
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
        CustomTextPosition(index: labelText.startIndex)
    }
    
    var endOfDocument: UITextPosition {
        CustomTextPosition(index: labelText.endIndex)
    }
    
    func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        guard let fromPosition = fromPosition as? CustomTextPosition, let toPosition = toPosition as? CustomTextPosition else {
            assert(false, "Unexpected type")
            return nil
        }
        return CustomTextRange(range: fromPosition.index..<toPosition.index)
    }
    
    func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        guard let position = position as? CustomTextPosition else {
            assert(false, "Unexpected type")
            return nil
        }
        
        let proposedIndex = labelText.index(position.index, offsetBy: offset)
        if proposedIndex == .invalid {
            /// Per documentation.
            return nil
        } else {
            return CustomTextPosition(index: proposedIndex)
        }
    }
    
    func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
        guard let position = position as? CustomTextPosition else {
            assert(false, "Unexpected type")
            return nil
        }
        switch direction {
        case .right, .down:
            return self.position(from: position, offset: offset)
        case .left, .up:
            return self.position(from: position, offset: -offset)
        @unknown default:
            fatalError()
        }
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
            assert(false, "Unexpected type")
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