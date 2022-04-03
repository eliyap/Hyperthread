//
//  CustomTextLabel+Geometry.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 27/3/22.
//

import UIKit

/// Functions relating to the on screen geometry of text.
extension CustomTextLabel {
    /// Docs: https://developer.apple.com/documentation/uikit/uitextinput/1614570-firstrect
    /// >  The first rectangle in a range of text.
    /// > You might use this rectangle to draw a correction rectangle.
    /// > The “first” in the name refers *the rectangle enclosing the first line*
    /// > when the range encompasses multiple lines of text.
    func firstRect(for range: UITextRange) -> CGRect {
        guard
            let start = range.start as? CustomTextPosition,
            let end = range.end as? CustomTextPosition
        else {
            assert(false, "Unexpected type")
            return .zero
        }
        
        let line = labelText.lines[start.index.row]
        let startIndex = start.index.column
        
        /// Find the end index.
        let endIndex: LiveLine.Index
        if start.index.row == end.index.row {
            endIndex = end.index.column
        } else {
            endIndex = line.endIndex
        }
        
        /// Find prefix width.
        let prefix = line.chars.prefix(upTo: start.index.column)
        let prefixWidth = prefix.map { (char: LiveLine.Element) in char.width }.reduce(0, +)

        /// Find fragment width.
        let fragment = line[startIndex..<endIndex]
        let fragmentWidth = fragment.map { (char: LiveLine.Element) in char.width }.reduce(0, +)

        /// Estimate line height.
        let lineHeight = Self.font.lineHeight

        return CGRect(
            x: prefixWidth + line.origin.x,
            y: CGFloat(start.index.row) * lineHeight + line.origin.y,
            width: fragmentWidth,
            height: lineHeight
        )
    }
    
    func caretRect(for position: UITextPosition) -> CGRect {
        guard let position = position as? CustomTextPosition else {
            assert(false, "Unexpected type")
            return .zero
        }

        let index = position.index
        let line = labelText.lines[index.row]
        let lineHeight = Self.font.lineHeight
        
        let prefix = line.chars.prefix(upTo: index.column)
        let prefixWidth = prefix.map { (char: LiveLine.Element) in char.width }.reduce(0, +)

        return CGRect(
            x: prefixWidth + line.origin.x,
            y: CGFloat(index.row) * lineHeight + line.origin.y,
            width: CustomTextLabel.caretWidth,
            height: lineHeight
        )
    }
    
    func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        guard
            let rangeStart = range.start as? CustomTextPosition,
            let rangeEnd = range.end as? CustomTextPosition
        else {
            assert(false, "Unexpected type")
            return []
        }
        
        let start = rangeStart.index
        let end = rangeEnd.index
        
        var result: [CustomTextSelectionRect] = []

        var lCol: LiveLine.Index
        var rCol: LiveLine.Index
        for row in start.row...end.row {
            let line = labelText.lines[row]

            lCol = row == start.row 
                ? start.column 
                : line.startIndex
            rCol = row == end.row 
                ? end.column 
                : line.endIndex
            
            let fragment = line[lCol..<rCol]
            let fragmentWidth = fragment.map { (char: LiveLine.Element) in char.width }.reduce(0, +)

            var rect = CGRect(
                x: line.origin.x,
                y: CustomTextLabel.font.lineHeight * CGFloat(row) + line.origin.y,
                width: fragmentWidth,
                height: CustomTextLabel.font.lineHeight
            )

            if row == start.row { 
                /// Calculate prefix width.
                let prefix = line.chars.prefix(upTo: start.column)
                let prefixWidth = prefix.map { (char: LiveLine.Element) in char.width }.reduce(0, +)
                rect.origin.x += prefixWidth
            }

            result.append(CustomTextSelectionRect(rect: rect, containsStart: row == start.row, containsEnd: row == end.row))
        }

        return result
    }
    
    func closestPosition(to point: CGPoint) -> UITextPosition? {
        guard
            let closest = labelText.lines.closest(to: point),
            let lineNo = labelText.lines.firstIndex(of: closest)
        else {
            return nil
        }
        
        let line = labelText.lines[lineNo]
        let lineWidth = line.chars.map { (char: LiveLine.Element) in char.width }.reduce(0, +)

        let result: CustomTextPosition
        if point.x < line.origin.x {
            /// Off to the left.
            let index = LiveDocument.Index(row: lineNo, column: line.startIndex)
            result = CustomTextPosition(index: index)
        } else if point.x > (lineWidth + line.width) {
            /// Off to the right.
            let index = LiveDocument.Index(row: lineNo, column: line.endIndex)
            result = CustomTextPosition(index: index)
        } else {
            /// Temporary `result`.
            var r: CustomTextPosition? = nil

            var accumulatedWidth: CGFloat = line.origin.x
            for lineIndex: LiveLine.Index in line.chars.indices {
                let charWidth: CGFloat = line[lineIndex].width
                if point.x < accumulatedWidth + charWidth {
                    let index = LiveDocument.Index(row: lineNo, column: lineIndex)
                    r = CustomTextPosition(index: index)
                    break
                }
                accumulatedWidth += charWidth
            }

            result = r ?? CustomTextPosition(index: LiveDocument.Index(row: lineNo, column: line.endIndex))
        }
        
        #if DEBUG
        if __LOG_LIVE_TEXT__ {
            LiveTextLog.debug("""
                \(#function)
                - point: \(point)
                - index: \(result.index)
                """, print: true, true)
        }
        #endif

        return result
    }
    
    func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
        guard let proposedPosition = closestPosition(to: point) else {
            return nil
        }

        guard
            let proposedPosition = proposedPosition as? CustomTextPosition,
            let rangeStart = range.start as? CustomTextPosition,
            let rangeEnd = range.end as? CustomTextPosition
        else {
            assert(false, "Unexpected type")
            return nil
        }

        return min(max(proposedPosition, rangeStart), rangeEnd)
    }
    
    func characterRange(at point: CGPoint) -> UITextRange? {
        guard labelText.isEmpty == false else {
            return nil
        }
        
        guard let textPosition = closestPosition(to: point) else {
            return nil
        }
        
        guard let textPosition = textPosition as? CustomTextPosition else {
            assert(false, "Unexpected type")
            return nil
        }
        
        let result: CustomTextRange
        
        let index = textPosition.index
        if index == labelText.endIndex {
            result = .init(range: labelText.index(index, offsetBy: -1)..<index)
        } else {
            result = .init(range: index..<labelText.index(index, offsetBy: 1))
        }
        
        #if DEBUG
        if __LOG_LIVE_TEXT__ {
            LiveTextLog.debug("""
                \(#function)
                - point: \(point)
                - index: \(index)
                """, print: true, true)
        }
        #endif
        
        return result
    }
}
