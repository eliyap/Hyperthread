import UIKit

class CustomTextRange: UITextRange {
	
	let startOffset: Int
	
    let endOffset: Int
	
	init(startOffset: Int, endOffset: Int) {
		self.startOffset = startOffset
		self.endOffset = endOffset
		super.init()
	}
	
	override var isEmpty: Bool {
		return startOffset == endOffset
	}
	
	override var start: UITextPosition {
		return CustomTextPosition(offset: startOffset)
	}
	
	override var end: UITextPosition {
		return CustomTextPosition(offset: endOffset)
	}
}
