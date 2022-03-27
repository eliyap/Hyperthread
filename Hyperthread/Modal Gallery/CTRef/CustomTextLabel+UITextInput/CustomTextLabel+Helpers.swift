//
//  CustomTextLabel+Helpers.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 27/3/22.
//

import UIKit

/// Functions not required for protocol conformance.
internal extension CustomTextLabel {
    /// Return the line index and the substring representing the line of a given `UITextPosition`
    /// - Parameter position: The position used to determine the line and index
    /// - Returns: a tuple containing the integer index and the substring representing the line that contains the passed in `position`
    func indexAndLine(from position: UITextPosition) -> (Int, Substring) {
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
    func stringIndex(from textPosition: UITextPosition) -> String.Index {
        guard let position = textPosition as? CustomTextPosition else {
            fatalError()
        }
        
        // Turn our text position into an index into `labelText`
        return labelText.index(labelText.startIndex, offsetBy: max(position.offset, 0))
    }
}
