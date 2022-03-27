// Licensed under the MIT License.

import UIKit

class CustomTextPosition: UITextPosition {
	/// The offset from the start index of the text position
	let offset: Int
	
	/// An initializer for a CustomTextPosition that takes in an offset
	/// - Parameter offset: the offset from the start index of this text position
	init(offset: Int) {
		self.offset = offset
	}
}

extension CustomTextPosition: Comparable {
	static func < (lhs: CustomTextPosition, rhs: CustomTextPosition) -> Bool {
		lhs.offset < rhs.offset
	}
	
	static func <= (lhs: CustomTextPosition, rhs: CustomTextPosition) -> Bool {
		lhs.offset <= rhs.offset
	}

	static func >= (lhs: CustomTextPosition, rhs: CustomTextPosition) -> Bool {
		lhs.offset >= rhs.offset
	}

	static func > (lhs: CustomTextPosition, rhs: CustomTextPosition) -> Bool {
		lhs.offset > rhs.offset
	}

}
