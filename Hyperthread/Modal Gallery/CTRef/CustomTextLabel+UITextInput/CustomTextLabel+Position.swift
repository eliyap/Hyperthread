//
//  CustomTextLabel+Position.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 27/3/22.
//

import UIKit
import BlackBox

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
        let result = labelText[customRange]
        
        #if DEBUG
        if __LOG_LIVE_TEXT__ {
            LiveTextLog.debug("""
                \(#function)
                - start: \(rangeStart.index)
                - end: \(rangeEnd.index)
                - result: \(result)
                """, print: true, true)
        }
        #endif
        
        return result
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
        return CustomTextPosition(index: labelText.startIndex)
    }
    
    var endOfDocument: UITextPosition {
        return CustomTextPosition(index: labelText.endIndex)
    }
    
    func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        guard let fromPosition = fromPosition as? CustomTextPosition, let toPosition = toPosition as? CustomTextPosition else {
            assert(false, "Unexpected type")
            return nil
        }
        
        assert(fromPosition.index != .invalid, "Invalid position")
        assert(toPosition.index != .invalid, "Invalid position")
        guard fromPosition.index <= toPosition.index else {
            BlackBox.Logger.general.error("""
                
                - fromPosition: \(fromPosition.index)
                - toPosition: \(toPosition.index)
                """)
            return CustomTextRange(range: toPosition.index..<fromPosition.index)
        }
        
        return CustomTextRange(range: fromPosition.index..<toPosition.index)
    }
    
    func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        guard let position = position as? CustomTextPosition else {
            assert(false, "Unexpected type")
            return nil
        }
        
        let proposedIndex = labelText.index(position.index, offsetBy: offset)
        
        #if DEBUG
        if __LOG_LIVE_TEXT__ {
            LiveTextLog.debug("""
                \(#function)
                - position: \(position.index)
                - offset: \(offset)
                - result: \(proposedIndex)
                """, print: true, true)
        }
        #endif
        
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
        
        #if DEBUG
        if __LOG_LIVE_TEXT__ {
            LiveTextLog.debug("""
                \(#function)
                """, print: true, true)
        }
        #endif
        
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

        #if DEBUG
        if __LOG_LIVE_TEXT__ {
            LiveTextLog.debug("""
                \(#function)
                - position: \(position.index)
                - other: \(other.index)
                """, print: true, true)
        }
        #endif
        
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
            let to = toPosition as? CustomTextPosition
        else {
            assert(false, "Unexpected type")
            return 0
        }
        
        return labelText.offset(from: from.index, to: to.index)
    }
    
    func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
        switch direction {
        case .left, .up:
            return range.start
        case .right, .down:
            return range.end
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
            return CustomTextRange(range: labelText.startIndex..<position.index)
        case .right, .down:
            return CustomTextRange(range: position.index..<labelText.endIndex)
        @unknown default:
            fatalError()
        }
    }
}
