//
//  CustomTextLabel+UITextInput.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 27/3/22.
//

import UIKit

/// `UITextInput` conformance for our `CustomTextLabel`
extension CustomTextLabel: UITextInput {
    
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
    
    // MARK: - Geometery
    func firstRect(for range: UITextRange) -> CGRect {
        guard
            let rangeStart = range.start as? CustomTextPosition,
            let rangeEnd = range.end as? CustomTextPosition
        else {
            assert(false, "Unexpected type")
            return .zero
        }
        
        /// Determine which line index and line the range starts in.
        let (startLineIndex, startLine) = indexAndLine(from: rangeStart)
        
        /// Determine the `x` position.
        var initialXPosition: CGFloat = 0
        var rectWidth: CGFloat = 0
        
        /// If our start and end line indices are the same, just get the whole range.
        if rangeStart.offset >= labelText.count {
            initialXPosition = self.intrinsicContentSize.width
        } else {
            let startTextIndex = labelText.index(labelText.startIndex, offsetBy: rangeStart.offset)
            let endTextIndex = labelText.index(startTextIndex, offsetBy: max(rangeEnd.offset - rangeStart.offset - 1, 0))
            
            /// Get the substring from the start of the line we're on to the start of our selection.
            let preSubstring = startLine.prefix(upTo: labelText.index(labelText.startIndex, offsetBy: rangeStart.offset))
            let preSize = NSAttributedString(string: String(preSubstring), attributes: attributes).size()
            
            /// Get the substring from the start of our range to the end of the line.
            let selectionLineEndIndex = min(endTextIndex, startLine.index(before: startLine.endIndex))
            let actualSubstring = startLine[startTextIndex...selectionLineEndIndex]
            let actualSize = NSAttributedString(string: String(actualSubstring), attributes: attributes).size()
            
            initialXPosition = preSize.width
            rectWidth = actualSize.width
        }
        
        return CGRect(
            x: initialXPosition,
            y: CGFloat(startLineIndex) * CustomTextLabel.font.lineHeight,
            width: rectWidth,
            height: CustomTextLabel.font.lineHeight
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
            selectionRects.append(CustomTextSelectionRect(rect: rect, writingDirection: .leftToRight, containsStart: containsStart, containsEnd: containsEnd))
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
    
    // MARK: - UIKeyInput
    
    var hasText: Bool {
        !labelText.isEmpty
    }
    
    // MARK: - Helpers
    
    /// Return the line index and the substring representing the line of a given `UITextPosition`
    /// - Parameter position: The position used to determine the line and index
    /// - Returns: a tuple containing the integer index and the substring representing the line that contains the passed in `position`
    private func indexAndLine(from position: UITextPosition) -> (Int, Substring) {
        // Turn our text position into an index into `labelText`
        let labelTextPositionIndex = stringIndex(from: position)
        
        // Split `labelText` into an array of substrings where each line is a substring
        let lines = CustomTextLabel.linesFromString(string: labelText)
        
        // Figure out which line contains our text position
        guard let lineIndex = lines.firstIndex(where: {
            // Check if our overall index into the string is on this line
            $0.startIndex <= labelTextPositionIndex && labelTextPositionIndex <= $0.endIndex
        }) else {
            // Our index we're looking for isn't contained in labelString? Let's just default to
            // the beginning of the string
            return (0, lines[0])
        }
        return (lineIndex, lines[lineIndex])
    }
    
    /// Turn  a `UITextPosition` into a String Index into `labelText`
    /// - Parameter textPosition: the text position to translate into a string index
    /// - Returns: the corresponding string index
    private func stringIndex(from textPosition: UITextPosition) -> String.Index {
        guard let position = textPosition as? CustomTextPosition else {
            fatalError()
        }
        
        // Turn our text position into an index into `labelText`
        return labelText.index(labelText.startIndex, offsetBy: max(position.offset, 0))
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
