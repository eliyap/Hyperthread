// Licensed under the MIT License.

import UIKit

struct MultiRectangleTextStore {
    
    let lines: [String]
    
    init(_ string: String) {
        self.lines = string
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map({ (substring: Substring) in
                return String(substring)
            })
    }
    
    var text: String {
        lines.joined(separator: "\n")
    }
    
    subscript(_ range: Range<MultiRectangleTextIndex>) -> String {
        guard range.isEmpty == false else { return "" }
        
        guard range.lowerBound != .invalid, range.upperBound != .invalid else {
            assert(false, "Invalid range")
            return ""
        }
        
        if range.lowerBound.row == range.upperBound.row {
			let line = lines[range.lowerBound.row]
			let substring = line[range.lowerBound.column..<range.upperBound.column]
			return String(substring)
		} else {
			let startLine = lines[range.lowerBound.row]
			let endLine = lines[range.upperBound.row]
			let middleLines = lines[(range.lowerBound.row + 1)..<range.upperBound.row]
			
			let start = startLine[range.lowerBound.column..<startLine.endIndex]
			let middle = middleLines.joined(separator: "\n")
            let end = endLine[endLine.startIndex..<range.upperBound.column]
			
			return start + "\n" + middle + "\n" + end
		}
    }
    
    var startIndex: MultiRectangleTextIndex {
        guard let first = lines.first else {
            return .invalid
        }
        
        return .init(row: 0, column: first.startIndex)
    }
    
    var endIndex: MultiRectangleTextIndex {
		guard let last = lines.last else {
			return .invalid
		}
		
		return .init(row: lines.count - 1, column: last.endIndex)
	}
    
    func index(_ original: MultiRectangleTextIndex, offsetBy offset: Int) -> MultiRectangleTextIndex {
		if offset == 0 {
			return original
		} else if offset > 0 { 
			var offset = offset
			var row = original.row
			var column = original.column
			while true {
				guard row < lines.count else {
					return .invalid
				}

				/// Check if offset exceeds line length.
				let line = lines[row]
				let remaining = line.distance(from: column, to: line.endIndex)
				
				if remaining < offset {
					/// If so, move to next line and repeat.
					offset -= remaining
					row += 1
					column = lines[row].startIndex
				} else {
					let newColumn = line.index(column, offsetBy: offset)
					return .init(row: row, column: newColumn)
				}
			}
		} else { 
			/// Make offset positive.
			var offset = -offset
			var row = original.row
			var column = original.column
			while true {
				guard row >= 0 else {
					return .invalid
				}

				/// Check if offset exceeds line length.
				let line = lines[row]
				let remaining = line.distance(from: line.startIndex, to: column)
				
				if remaining < offset {
					/// If so, move to previous line and repeat.
					offset -= remaining
					row -= 1
					column = lines[row].endIndex
				} else {
					let newColumn = line.index(column, offsetBy: -offset)
					return .init(row: row, column: newColumn)
				}
			}
		}
    }
    
    var isEmpty: Bool {
        lines.isEmpty
    }
}

/// 2D index into a `MultiRectangleTextStore`.
struct MultiRectangleTextIndex {
	/// The "line" on which the index is located.
	/// Min: 0
	/// Max: lines.count - 1
    let row: Int
	
	/// The "column" on which the index is located.
    let column: String.Index
    
    public static let invalid: Self = .init(row: NSNotFound, column: "".startIndex)
}

extension MultiRectangleTextIndex: Comparable {
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
    var labelText: MultiRectangleTextStore = .init("") {
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
	var currentSelectedTextRange: UITextRange? = CustomTextRange(startOffset: 0, endOffset: 0)
	
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
