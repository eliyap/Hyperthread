//
//  AbsoluteFrame.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 15/3/22.
//

import UIKit

extension UIView {
    /// The view's frame in window coordinates.
    func absoluteFrame() -> CGRect {
        /// Docs: https://developer.apple.com/documentation/uikit/uiview/1622498-convert
        /// > If `view` is `nil`, this method instead converts from window base coordinates.
        convert(frame, to: nil)
    }
}
