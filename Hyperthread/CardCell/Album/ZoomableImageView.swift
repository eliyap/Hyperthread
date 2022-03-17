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
    
    /// Live-tracks user's zoom scale to enable "over-zoom" haptic feedback.
    private var mostRecentZoomScale: CGFloat? = nil
    
    /// Use light feedback, since "overzooming" is not the user's "fault".
    private let hapticGenerator: UISelectionFeedbackGenerator = .init()
    
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
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        guard let mostRecentZoomScale = mostRecentZoomScale else { return }
        if (mostRecentZoomScale < minimumZoomScale) || (mostRecentZoomScale > maximumZoomScale) {
//            hapticGenerator.selectionChanged()
            print("boop")
        }
        
        /// Reset tracking.
        self.mostRecentZoomScale = nil
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        print("starting zoom...")
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        /// Zoom is ongoing, and will likely end soon, so prepare to provide feedback.
        hapticGenerator.prepare()
        
        let reportedScale = scrollView.zoomScale
        
        /// If the user "over-zooms", the zoom level snaps back to bounds, which is reported to the delegate.
        /// Since we're interested in detecting this "snap back", we ignore the bounded value.
        guard (reportedScale != minimumZoomScale) && (reportedScale != maximumZoomScale) else {
            return
        }
        mostRecentZoomScale = reportedScale
    }
}
