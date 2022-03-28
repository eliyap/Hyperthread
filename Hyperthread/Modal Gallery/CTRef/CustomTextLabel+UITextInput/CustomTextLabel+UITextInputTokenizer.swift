//
//  CustomTextLabel+UITextInputTokenizer.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 28/3/22.
//

import UIKit

extension CustomTextLabel: UITextInputTokenizer {
    func rangeEnclosingPosition(_ position: UITextPosition, with granularity: UITextGranularity, inDirection direction: UITextDirection) -> UITextRange? {
        /// Enclose business logic to allow debugging statements.
        func shadow(_ position: UITextPosition, with granularity: UITextGranularity, inDirection direction: UITextDirection) -> UITextRange? {
            guard let position = position as? CustomTextPosition else {
                assert(false, "Unexpected type")
                
                /// Return empty range.
                return nil
            }
            
            /// https://ericasadun.com/2014/07/08/swift-coping-with-bad-enum-typedefs/
            /// Looks like they glommed two enums together and just let it sit there.
            switch direction.rawValue {
            case UITextStorageDirection.forward.rawValue, UITextLayoutDirection.right.rawValue, UITextLayoutDirection.down.rawValue:
                return rangeAfter(position, with: granularity)
            
            case UITextStorageDirection.backward.rawValue, UITextLayoutDirection.left.rawValue, UITextLayoutDirection.up.rawValue:
                return rangeBefore(position, with: granularity)
            
            default:
                assert(false, "Unknown direction value \(direction.rawValue)")
                
                /// Return empty range.
                return CustomTextRange(range: position.index..<position.index)
            }
        }
                
        #if DEBUG
        if __LOG_LIVE_TEXT__ {
            if let position = position as? CustomTextPosition {
                LiveTextLog.debug("""
                    \(#function)
                    - position: \(position.index)
                    - granularity: \(granularity)
                    - direction: \(direction)
                    """, print: true, true)
            }
        }
        #endif
        
        return shadow(position, with: granularity, inDirection: direction)
    }
    
    private func rangeAfter(_ position: CustomTextPosition, with granularity: UITextGranularity) -> CustomTextRange {
        let line = labelText.lines[position.index.row]
        
        /// Check is not at end of line.
        guard position.index.column != line.endIndex else {
            /// Return empty range.
            return CustomTextRange(range: position.index..<position.index)
        }
        
        let endIndex: LiveString.Index
        switch granularity {
        case .character:
            let newColumn = line.index(position.index.column, offsetBy: +1)
            endIndex = .init(row: position.index.row, column: newColumn)
        
        case .word:
            /// Check is not at word boundary.
            let nextCharacter: Character = line[position.index.column]
            guard nextCharacter.isWhitespace == false else {
                /// Return empty range.
                return CustomTextRange(range: position.index..<position.index)
            }
            
            let trailing = line[position.index.column..<line.endIndex]
            if let nextWhitespace = trailing.firstIndex(where: { char in char.isWhitespace }) {
                endIndex = .init(row: position.index.row, column: nextWhitespace)
            } else {
                endIndex = .init(row: position.index.row, column: line.endIndex)
            }
        
        case .sentence, .paragraph, .line:
            endIndex = .init(row: position.index.row, column: line.endIndex)
        
        case .document:
            endIndex = labelText.endIndex
        
        @unknown default:
            assert(false, "Unknown granularity \(granularity.rawValue)")
            
            /// Return empty range.
            return CustomTextRange(range: position.index..<position.index)
        }
        
        return CustomTextRange(range: position.index..<endIndex)
    }
    
    private func rangeBefore(_ position: CustomTextPosition, with granularity: UITextGranularity) -> CustomTextRange {
        let line = labelText.lines[position.index.row]
        
        /// Check is not at end of line.
        guard position.index.column != line.startIndex else {
            /// Return empty range.
            return CustomTextRange(range: position.index..<position.index)
        }
        
        let startIndex: LiveString.Index
        switch granularity {
        case .character:
            let newColumn = line.index(position.index.column, offsetBy: -1)
            startIndex = .init(row: position.index.row, column: newColumn)
        
        case .word:
            /// Check is not at word boundary.
            let prevColumn = line.index(position.index.column, offsetBy: -1)
            let prevCharacter: Character = line[prevColumn]
            guard prevCharacter.isWhitespace == false else {
                /// Return empty range.
                return CustomTextRange(range: position.index..<position.index)
            }
            
            let leading = line[position.index.column..<line.endIndex]
            if let nextWhitespace = leading.lastIndex(where: { char in char.isWhitespace }) {
                let afterWhitespace = line.index(nextWhitespace, offsetBy: 1)
                startIndex = .init(row: position.index.row, column: afterWhitespace)
            } else {
                startIndex = .init(row: position.index.row, column: line.startIndex)
            }
        
        case .sentence, .paragraph, .line:
            startIndex = .init(row: position.index.row, column: line.startIndex)
        
        case .document:
            startIndex = labelText.startIndex
        
        @unknown default:
            assert(false, "Unknown granularity \(granularity.rawValue)")
            
            /// Return empty range.
            return CustomTextRange(range: position.index..<position.index)
        }
        
        return CustomTextRange(range: startIndex..<position.index)
    }
    
    func isPosition(_ position: UITextPosition, atBoundary granularity: UITextGranularity, inDirection direction: UITextDirection) -> Bool {
        guard let position = position as? CustomTextPosition else {
            assert(false, "Unexpected type")
            return true
        }
        
        let line = labelText.lines[position.index.row]
        
        /// https://ericasadun.com/2014/07/08/swift-coping-with-bad-enum-typedefs/
        /// Looks like they glommed two enums together and just let it sit there.
        switch direction.rawValue {
        case UITextStorageDirection.forward.rawValue, UITextLayoutDirection.right.rawValue, UITextLayoutDirection.down.rawValue:
            switch granularity {
            case .character:
                /// All characters are by definition at a character boundary.
                return true
            
            case .word:
                /// Check line boundary first.
                guard position.index.column != line.endIndex else {
                    return true
                }
                
                /// Check is at word boundary.
                let nextCharacter: Character = line[position.index.column]
                return nextCharacter.isWhitespace
            
            case .sentence, .paragraph, .line:
                return position.index.column == line.endIndex
            
            case .document:
                return position.index == labelText.endIndex
            
            @unknown default:
                assert(false, "Unknown granularity \(granularity.rawValue)")
                return true
            }
        
        case UITextStorageDirection.backward.rawValue, UITextLayoutDirection.left.rawValue, UITextLayoutDirection.up.rawValue:
            switch granularity {
            case .character:
                /// All characters are by definition at a character boundary.
                return true
            
            case .word:
                /// Check line boundary first.
                guard position.index.column != line.startIndex else {
                    return true
                }
                
                /// Check is at word boundary.
                let prevIndex = line.index(position.index.column, offsetBy: -1)
                let prevCharacter: Character = line[prevIndex]
                return prevCharacter.isWhitespace
            
            case .sentence, .paragraph, .line:
                return position.index.column == line.startIndex
            
            case .document:
                return position.index == labelText.startIndex
            
            @unknown default:
                assert(false, "Unknown granularity \(granularity.rawValue)")
                return true
            }
        
        default:
            assert(false, "Unknown direction value \(direction.rawValue)")
            return true
        }
    }
    
    func position(from position: UITextPosition, toBoundary granularity: UITextGranularity, inDirection direction: UITextDirection) -> UITextPosition? {
        guard let position = position as? CustomTextPosition else {
            assert(false, "Unexpected type")
            
            /// Return empty range.
            return nil
        }
        
        /// https://ericasadun.com/2014/07/08/swift-coping-with-bad-enum-typedefs/
        /// Looks like they glommed two enums together and just let it sit there.
        switch direction.rawValue {
        case UITextStorageDirection.forward.rawValue, UITextLayoutDirection.right.rawValue, UITextLayoutDirection.down.rawValue:
            return rangeAfter(position, with: granularity).end
        
        case UITextStorageDirection.backward.rawValue, UITextLayoutDirection.left.rawValue, UITextLayoutDirection.up.rawValue:
            return rangeBefore(position, with: granularity).start
        
        default:
            assert(false, "Unknown direction value \(direction.rawValue)")
            
            /// Return empty range.
            return nil
        }
    }
    
    func isPosition(_ position: UITextPosition, withinTextUnit granularity: UITextGranularity, inDirection direction: UITextDirection) -> Bool {
        return !self.isPosition(position, atBoundary: granularity, inDirection: direction)
    }
}
