// Licensed under the MIT License.

import UIKit

final class CustomTextPosition: UITextPosition {
	/// The offset from the start index of the text position
    public let index: LiveDocument.Index
	
	init(index: LiveDocument.Index) {
		self.index = index
	}
}

extension CustomTextPosition: Comparable {
	static func < (lhs: CustomTextPosition, rhs: CustomTextPosition) -> Bool {
		lhs.index < rhs.index
	}
}
