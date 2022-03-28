// Licensed under the MIT License.

import UIKit

extension LiveString {
    /// 2D index into a `LiveString`.
    struct Index {
        /// The "line" on which the index is located.
        /// Min: 0
        /// Max: lines.count - 1
        let row: Int
        
        /// The "column" on which the index is located.
        let column: String.Index
        
        public static let invalid: Self = .init(row: NSNotFound, column: "".startIndex)
    }
}

extension LiveString.Index: Comparable {
    static func <(lhs: Self, rhs: Self) -> Bool {
		if (lhs.row == rhs.row) {
			return lhs.column < rhs.column
		} else { 
			return lhs.row < rhs.row
		}
	}
}

/// A simple custom text label that conforms to `UITextInput` for use with `UITextInteraction`
class CustomTextLabel: UIView {
	
    /// The width of the caret rect for use in `UITextInput` conformance
    public static let caretWidth: CGFloat = 2.0
    
    /// The font used by the the `CustomTextLabel`
    public static let font = UIFont.systemFont(ofSize: 20.0)
    
    /// Primary initializer that takes in the labelText to display for this label
	/// - Parameter labelText: the string to display
	init(labelText: String) {
        self.labelText = .init(labelText)
		super.init(frame: .zero)
        
        backgroundColor = .clear
	}
	
	/// The text to be drawn to screen by this `CustomTextLabel`
    var labelText: LiveString = .init("") {
		didSet {
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
		}
	}
	
	/// A simple draw call override that uses `NSAttributedString` to draw `labelText` with `attributes`
	override func draw(_ rect: CGRect) {
		super.draw(rect)
        let attributedString = NSAttributedString(string: labelText.text, attributes: attributes)
		attributedString.draw(in: rect)
	}
	
	/// The attributes used by this text label to draw the text in `labelText`
    var attributes: [NSAttributedString.Key: Any]? {
        [
            .font: Self.font
        ]
    }
	
	/// The currently selected text range, which gets modified via UITextInput's callbacks
	var currentSelectedTextRange: UITextRange? = nil
	
	/// A text view should be allowed to become first responder
	override var canBecomeFirstResponder: Bool {
		true
	}
	
	/// Return an array of substrings split on the newline character
	/// - Parameter string: the string to be split
	/// - Returns: an array of the substrings, split on `\n`
	public static func linesFromString(string: String) -> [Substring] {
		return string.split(separator: "\n", omittingEmptySubsequences: false)
	}
    
    required init?(coder: NSCoder) {
        fatalError("No.")
    }
}
