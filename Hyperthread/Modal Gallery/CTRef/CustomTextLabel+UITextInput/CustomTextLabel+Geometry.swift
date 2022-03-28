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
        /// Turn our text position into an index into `labelText`.
        let labelTextPositionIndex = stringIndex(from: position)
        
        /// Determine what line index and line our text position is on.
        let (lineIndex, line) = indexAndLine(from: position)
        
        // Get the substring from the beginning of that line up to our text position
        let substring = line.prefix(upTo: labelTextPositionIndex)
        
        // Check the size of that substring, our caret should draw just to the right edge of this range
        let size = NSAttributedString(string: String(substring), attributes: attributes).size()
        
        // Make the caret rect, accounting for which line we're on
        return CGRect(
            x: size.width,
            y: CustomTextLabel.font.lineHeight * CGFloat(lineIndex),
            width: CustomTextLabel.caretWidth,
            height: CustomTextLabel.font.lineHeight
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
        
        let lines = CustomTextLabel.linesFromString(string: labelText)
        // Determine which line index and line the range starts and ends in
        let (startLineIndex, _) = indexAndLine(from: rangeStart)
        let (endLineIndex, _) = indexAndLine(from: rangeEnd)
        
        // Translate our range indexes into text indexes
        let startTextIndex = labelText.index(labelText.startIndex, offsetBy: rangeStart.offset)
        let endTextIndex = labelText.index(startTextIndex, offsetBy: max(rangeEnd.offset - rangeStart.offset - 1, 0))
        
        var selectionRects: [CustomTextSelectionRect] = []
        for (index, line) in lines.enumerated() {
            /// Check if line is valid selection target.
            guard line.isEmpty == false, index >= startLineIndex, index <= endLineIndex else {
                continue
            }
            
            let containsStart = line.startIndex <= startTextIndex && startTextIndex < line.endIndex
            let containsEnd = line.startIndex <= endTextIndex && endTextIndex < line.endIndex
            
            /// Get substring from start of range to end of line.
            let selectionStartIndex = max(startTextIndex, line.startIndex)
            let selectionEndIndex = max(min(endTextIndex, line.index(before: line.endIndex)), selectionStartIndex)
            let actualSubstring = line[selectionStartIndex..<selectionEndIndex]
            let actualSize = NSAttributedString(string: String(actualSubstring), attributes: attributes).size()
            
            var xPos: CGFloat = 0
            if containsStart {
                /// Get substring from the start of current line to start of selection.
                let preSubstring = line.prefix(upTo: labelText.index(labelText.startIndex, offsetBy: rangeStart.offset))
                let preSize = NSAttributedString(string: String(preSubstring), attributes: attributes).size()
                xPos = preSize.width
            }
            
            let rectWidth = actualSize.width
            
            // Make the selection rect for this line
            let rect = CGRect(
                x: xPos,
                y: CGFloat(index) * CustomTextLabel.font.lineHeight,
                width: rectWidth,
                height: CustomTextLabel.font.lineHeight
            )
            selectionRects.append(CustomTextSelectionRect(rect: rect, containsStart: containsStart, containsEnd: containsEnd))
        }
        
        // Return our constructed array
        return selectionRects
    }
    
    func closestPosition(to point: CGPoint) -> UITextPosition? {
        /// Find the line.
        let lines = CustomTextLabel.linesFromString(string: labelText)
        var lineNo = Int(point.y /  CustomTextLabel.font.lineHeight)
        lineNo = min(lineNo, lines.endIndex - 1)
        let line = lines[lineNo]
        
        /// Find character where the `x` falls inside.
        var x: CGFloat = 0.0
        var lineOffset: Int? = nil
        
        
        /// TODO – demonstrates how we can restrict selection to 1 line at a time.
        var candidates = Array(line.enumerated())
        candidates = Array([candidates.first, candidates.last].compacted())
        
        for (lineIdx, char) in candidates {
            /// Render and measure character's on screen width.
            let charWidth = NSAttributedString(string: String(char), attributes: attributes).size().width
            
            /// Check if `x` is within range.
            guard (x <= point.x) && (point.x < x + charWidth) else {
                /// If not, proceed to next character.
                x = x + charWidth
                continue
            }
            
            /// Decide to round partial character up or down.
            let widthFraction = (point.x - x) / charWidth
            let adj = (widthFraction < 0.5) ? 0 : 1
            
            lineOffset = lineIdx + adj
            break
        }
        
        /// `x` exceeded, assume position is past the end of the line.
        if lineOffset == nil, let (endIdx, _) = candidates.last {
            lineOffset = endIdx
        }
        
        guard let lineOffset = lineOffset else { return nil }
        
        /// Calculate our offset in terms of the full string, not just this line.
        let lineIndex = line.index(line.startIndex, offsetBy: lineOffset)
        let labelOffset = labelText.distance(from: labelText.startIndex, to: lineIndex)
        return CustomTextPosition(offset: labelOffset)
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
        guard let textPosition = closestPosition(to: point) else {
            return nil
        }
        
        guard let textPosition = textPosition as? CustomTextPosition else {
            assert(false, "Unexpected type")
            return nil
        }

        return CustomTextRange(startOffset: textPosition.offset, endOffset: textPosition.offset + 1)
    }
}
