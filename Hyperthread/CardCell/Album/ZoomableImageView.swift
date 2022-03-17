//
//  ZoomableImageView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 17/3/22.
//

import UIKit
import SDWebImage

final class ZoomableImageView: UIScrollView {
    
    private let imageView: UIImageView = .init()
    
    @MainActor
    init() {
        super.init(frame: .zero)

        /// Configure `self`.
        alwaysBounceVertical = false
        alwaysBounceHorizontal = false
        minimumZoomScale = 1
        maximumZoomScale = 5
        clipsToBounds = false
        self.delegate = self
        
        /// Match iOS's Photos app.
        decelerationRate = .fast
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        
        /// Configure `imageView`.
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            /// Use `≤`, not `=`, to keep small images at their intrinsic size.
            imageView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor),
            imageView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor),
            /// Small images default to top leading corner if not centered.
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ZoomableImageView: FramedImageView {
    func load(from url: String) {
        imageView.sd_setImage(with: URL(string: url), completed: { (image: UIImage?, error: Error?, cacheType: SDImageCacheType, url: URL?) in
            /// Nothing.
        })
    }
}

extension ZoomableImageView: UIScrollViewDelegate {
    /// Required to enable zoom.
    /// Source: https://www.hackingwithswift.com/example-code/uikit/how-to-support-pinch-to-zoom-in-a-uiscrollview
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
