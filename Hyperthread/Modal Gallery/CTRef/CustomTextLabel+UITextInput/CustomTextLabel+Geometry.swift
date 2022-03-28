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
        let endIndex: String.Index
        if start.index.row == end.index.row {
            endIndex = end.index.column
        } else {
            endIndex = line.endIndex
        }
        
        /// Find prefix width.
        let prefix = line.prefix(upTo: start.index.column)
        let prefixWidth = NSAttributedString(string: String(prefix), attributes: attributes).size().width

        /// Find fragment width.
        let fragment = line[startIndex..<endIndex]
        let fragmentWidth = NSAttributedString(string: String(fragment), attributes: attributes).size().width

        /// Estimate line height.
        let lineHeight = Self.font.lineHeight

        return CGRect(
            x: prefixWidth,
            y: CGFloat(start.index.row) * lineHeight,
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
        
        let prefix = line.prefix(upTo: index.column)
        let prefixWidth = NSAttributedString(string: String(prefix), attributes: attributes).size().width

        return CGRect(
            x: prefixWidth,
            y: CGFloat(index.row) * lineHeight,
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

        var lCol: String.Index
        var rCol: String.Index
        for row in start.row...end.row {
            let line = labelText.lines[row]

            lCol = row == start.row 
                ? start.column 
                : line.startIndex
            rCol = row == end.row 
                ? end.column 
                : line.endIndex
            
            let fragment = line[lCol..<rCol]
            let size = NSAttributedString(string: String(fragment), attributes: attributes).size()

            var rect = CGRect(
                x: 0,
                y: CustomTextLabel.font.lineHeight * CGFloat(row),
                width: size.width,
                height: CustomTextLabel.font.lineHeight
            )

            if row == start.row { 
                /// Calculate prefix width.
                let prefix = line.prefix(upTo: start.column)
                let prefixWidth = NSAttributedString(string: String(prefix), attributes: attributes).size().width
                rect.origin.x += prefixWidth
            }

            result.append(CustomTextSelectionRect(rect: rect, containsStart: row == start.row, containsEnd: row == end.row))
        }

        return result
    }
    
    func closestPosition(to point: CGPoint) -> UITextPosition? {
        /// Estimate line from `y`.
        let lineHeight = CustomTextLabel.font.lineHeight
        var lineNo = Int(point.y / lineHeight)
        
        /// Clamp line to valid indices.
        if lineNo < 0 {
            lineNo = 0
        } else if lineNo >= labelText.lines.count {
            lineNo = labelText.lines.count - 1
        }

        let line = labelText.lines[lineNo]
        let lineWidth = NSAttributedString(string: line, attributes: attributes).size().width
        
        if point.x < (lineWidth / 2) {
            /// Closest to the left.
            let index = LiveString.Index(row: lineNo, column: line.startIndex)
            return CustomTextPosition(index: index)
        } else {
            /// Closest to the right.
            let index = LiveString.Index(row: lineNo, column: line.endIndex)
            return CustomTextPosition(index: index)
        }
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
        
        let index = textPosition.index
        if index == labelText.endIndex {
            return CustomTextRange(range: labelText.index(index, offsetBy: -1)..<index)
        } else {
            return CustomTextRange(range: index..<labelText.index(index, offsetBy: 1))
        }
    }
}
