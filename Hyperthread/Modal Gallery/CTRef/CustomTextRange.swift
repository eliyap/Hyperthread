import UIKit

class CustomTextRange: UITextRange {
	
    let range: Range<LiveDocument.Index>
	
	init(range: Range<LiveDocument.Index>) {
        self.range = range
		super.init()
	}
	
	override var isEmpty: Bool {
        return range.isEmpty
	}
	
	override var start: UITextPosition {
        return CustomTextPosition(index: range.lowerBound)
	}
	
	override var end: UITextPosition {
		return CustomTextPosition(index: range.upperBound)
	}
}
