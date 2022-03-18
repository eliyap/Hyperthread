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
        
        #if DEBUG
        let __FRAME_BORDER__ = true
        if __FRAME_BORDER__ {
            layer.borderWidth = 2
            layer.borderColor = UIColor.blue.cgColor
        }
        
        let __IMAGE_FRAME__ = true
        if __IMAGE_FRAME__ {
            imageView.layer.borderWidth = 4
            imageView.layer.borderColor = UIColor.red.cgColor
        }
        #endif
        
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
    func setAnimationStartPoint(frame: CGRect) {
        updateFloatCenter(frame: frame)
    }
    
    func setAnimationEndPoint(frame: CGRect) {
        updateFloatCenter(frame: frame)
    }
}

extension ZoomableImageView: UIScrollViewDelegate {
    /// Required to enable zoom.
    /// Source: https://www.hackingwithswift.com/example-code/uikit/how-to-support-pinch-to-zoom-in-a-uiscrollview
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) -> Void {
        updateFloatCenter()
    }
    
    /// Abuses `contentInset` to cause undersized content to be centered,
    /// both horizontally and vertically.
    func updateFloatCenter(frame: CGRect? = nil) {
        /// Use own frame if none provided.
        let frame = frame ?? self.frame
        
        let excessHeight = frame.height - imageView.frame.height
        let yInset = max(0, excessHeight / 2)
        
        let excessWidth = frame.width - imageView.frame.width
        let xInset = max(0, excessWidth / 2)
        
        contentInset = UIEdgeInsets(top: yInset, left: xInset, bottom: yInset, right: xInset)
    }
}

extension ZoomableImageView: SizeAwareView {
    func didTransition(to size: CGSize) {
        updateFloatCenter()
    }
}

/// Provides a view whose frame we can target for a `matchedGeometryEffect` style transition.
protocol GeometryTargetProvider: UIView {
    var targetView: UIView { get }
}

final class _ZoomableImageView: UIScrollView {
    
    public let imageView: UIImageView = .init()
    
    private var aspectConstraint: NSLayoutConstraint? = nil

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
        ])
        
        #if DEBUG
        let __FRAME_BORDER__ = true
        if __FRAME_BORDER__ {
            layer.borderWidth = 2
            layer.borderColor = UIColor.blue.cgColor
        }
        
        let __IMAGE_FRAME__ = true
        if __IMAGE_FRAME__ {
            imageView.layer.borderWidth = 4
            imageView.layer.borderColor = UIColor.red.cgColor
        }
        #endif
        
        /// Set up double tap to zoom.
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(didDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
    }
    
    public func configure(image: UIImage?, frame: CGRect) -> Void {
        guard let image = image else {
            TableLog.warning("Received nil image in modal!")
            return
        }

        imageView.image = image
        
        /// Constrain to exact aspect ratio.
        let aspectRatio: CGFloat
        aspectRatio = image.size.width / image.size.height
        let newAspectConstraint = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: aspectRatio)
        replace(object: self, on: \.aspectConstraint, with: newAspectConstraint)
        
        predictInsets(image: image, frame: frame)
    }
    
    func predictInsets(frame: CGRect) -> Void {
        guard let image = imageView.image else {
            assert(false, "No image to predict with!")
            return
        }
        predictInsets(image: image, frame: frame)
    }
    
    func predictInsets(image: UIImage, frame: CGRect) -> Void {
        /// Predict `imageView` height.
        let tooTall = image.size.height > frame.height
        let tooWide = image.size.width > frame.width
        let size: CGSize
        switch (tooTall, tooWide) {
        case (false, false):
            size = image.size
            
        case (false, true):
            size = CGSize(
                width: frame.width,
                height: image.size.height * (frame.width / image.size.width)
            )
            
        case (true, false):
            size = CGSize(
                width: image.size.width * (frame.height / image.size.height),
                height: frame.height
            )
            
        case (true, true):
            if (image.size.height / image.size.width) > (frame.height / frame.width) {
                /// Image is proportionally taller than frame, will be height constrained.
                size = CGSize(
                    width: image.size.width * (frame.height / image.size.height),
                    height: frame.height
                )
            } else {
                /// Image is proportionally shorter than frame, will be width constrained.
                size = CGSize(
                    width: frame.width,
                    height: image.size.height * (frame.width / image.size.width)
                )
            }
        }
        
        print("predicted size: \(size)")
        let excessHeight = frame.height - size.height
        let yInset = max(0, excessHeight / 2)
        
        let excessWidth = frame.width - size.width
        let xInset = max(0, excessWidth / 2)
        
        contentInset = UIEdgeInsets(top: yInset, left: xInset, bottom: yInset, right: xInset)
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

extension _ZoomableImageView: UIScrollViewDelegate {
    /// Required to enable zoom.
    /// Source: https://www.hackingwithswift.com/example-code/uikit/how-to-support-pinch-to-zoom-in-a-uiscrollview
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) -> Void {
        updateFloatCenter()
    }
    
    /// Abuses `contentInset` to cause undersized content to be centered,
    /// both horizontally and vertically.
    func updateFloatCenter(frame: CGRect? = nil) {
        /// Use own frame if none provided.
        let frame = frame ?? self.frame
        
        let excessHeight = frame.height - imageView.frame.height
        let yInset = max(0, excessHeight / 2)
        
        let excessWidth = frame.width - imageView.frame.width
        let xInset = max(0, excessWidth / 2)
        
        contentInset = UIEdgeInsets(top: yInset, left: xInset, bottom: yInset, right: xInset)
    }
}

extension _ZoomableImageView: SizeAwareView {
    func didTransition(to size: CGSize) {
        updateFloatCenter()
    }
}

extension _ZoomableImageView: GeometryTargetProvider {
    var targetView: UIView {
        imageView
    }
}
