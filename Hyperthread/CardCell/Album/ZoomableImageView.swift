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
    init(image: UIImage?) {
        super.init(frame: .zero)
        imageView.image = image
        
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
        
        let aspectRatio: CGFloat
        if let image = image {
            aspectRatio = image.size.width / image.size.height
        } else {
            aspectRatio = 1.0
        }
        NSLayoutConstraint.activate([
            /// Use `≤`, not `=`, to keep small images at their intrinsic size.
            imageView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor),
            imageView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor),
            /// Constrain to exact aspect ratio.
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: aspectRatio),
        ])
        
        /// Set up double tap to zoom.
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(didDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
    }
    
    @objc
    private func didDoubleTap(recognizer: UITapGestureRecognizer) -> Void {
        if zoomScale == 1 {
            /// Zoom into tapped area.
            let rect = zoomRectForScale(scale: maximumZoomScale, center: recognizer.location(in: recognizer.view))
            zoom(to: rect, animated: true)
        } else {
            /// Zoom back out.
            setZoomScale(1, animated: true)
        }
    }
    
    /// Adapted from: https://stackoverflow.com/questions/3967971/how-to-zoom-in-out-photo-on-double-tap-in-the-iphone-wwdc-2010-104-photoscroll/46143499#46143499
    private func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        let newCenter = imageView.convert(center, from: self)
        let width = imageView.frame.size.width  / scale
        let height = imageView.frame.size.height / scale
        return CGRect(
            origin: CGPoint(
                x: newCenter.x - (width / 2.0),
                y: newCenter.y - (height / 2.0)
            ),
            size: CGSize(width: width, height: height)
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ZoomableImageView: FramedImageView {
}

extension ZoomableImageView: UIScrollViewDelegate {
    /// Required to enable zoom.
    /// Source: https://www.hackingwithswift.com/example-code/uikit/how-to-support-pinch-to-zoom-in-a-uiscrollview
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    /// Abuses `contentInset` to cause undersized content to be centered,
    /// both horizontally and vertically.
    func updateFloatCenter() {
        let excessHeight = frame.height - imageView.frame.height
        let yInset = max(0, excessHeight / 2)
        
        let excessWidth = frame.width - imageView.frame.width
        let xInset = max(0, excessWidth / 2)
        
        contentInset = UIEdgeInsets(top: yInset, left: xInset, bottom: yInset, right: xInset)
    }
}
