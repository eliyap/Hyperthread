//
//  UIImage.fill.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 13/2/22.
//

import UIKit
import BlackBox

internal extension UIImage {
    /// Creates an image filled with solid color.
    /// Source: https://stackoverflow.com/questions/26542035/create-uiimage-with-solid-color-in-swift
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

/// Templated, resizable, solid image intended to fill a `UIVisualEffectView`.
/// This causes the vibrancy effect to fill the whole view.
///
/// > `UIImageView` objects with images that have a rendering mode of `UIImage.RenderingMode.alwaysTemplate`
/// > as well as `UILabel` objects will update automatically.
///
/// Source: https://developer.apple.com/documentation/uikit/uivibrancyeffect
internal extension UIImageView {
    static func makeSolidTemplate(color: UIColor) -> UIImageView {
        let view = UIImageView()
        guard let image = UIImage(color: UIColor.black)?.withRenderingMode(.alwaysTemplate) else {
            Logger.general.error("Failed to render template image!")
            assert(false)
            return view
        }
        view.image = image
        view.contentMode = .scaleToFill
        return view
    }
}
