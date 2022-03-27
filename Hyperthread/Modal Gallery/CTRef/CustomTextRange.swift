import UIKit

class CustomTextRange: UITextRange {
	
    let range: Range<MultiRectangleTextIndex>
	
	init(range: Range<MultiRectangleTextIndex>) {
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
