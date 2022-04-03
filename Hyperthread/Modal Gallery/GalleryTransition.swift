//
//  GalleryTransition.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 18/3/22.
//

import UIKit

/// Views pop above navigation bars when animated in, we reduce transparency to make that less jarring.
let transitionOpacity: Float = 0.25

public extension UIColor {
    /// Similar to iOS's Photos App, use a "dark room" style black background for image galleries.
    static let galleryBackground: UIColor = .black
    static let galleryShade: UIColor = .galleryBackground.withAlphaComponent(0.6)
    static let galleryUI: UIColor = .white
}

final class GalleryPresentingAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    public static let duration = 0.25
    
    private weak var rootView: UIView?
    
    init(rootView: UIView?) {
        self.rootView = rootView
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Self.duration
    }
    
    func animateTransition(using context: UIViewControllerContextTransitioning) {
        guard let toView = context.view(forKey: .to) else {
            assert(false, "Could not obtain originating views!")
            context.completeTransition(false)
            return
        }
        
        guard let targetProvider = toView as? GeometryTargetProvider else {
            assert(false, "Missing target provider!")
            context.completeTransition(false)
            return
        }
        
        guard let galleryView = toView as? GalleryView else {
            assert(false, "Unexpected view type!")
            context.completeTransition(false)
            return
        }
        
        let target: UIView = { /// Place target view into its final position by forcing a layout pass.
            context.containerView.addSubview(galleryView)
            galleryView.constrain(to: context.containerView)
            
            /// Forcing a layout causes the `UICollectionView` to create and display a cell, allowing us to access its contents.
            galleryView.setNeedsLayout()
            context.containerView.layoutIfNeeded()
            
            return targetProvider.targetView
        }()
        
        let startingFrame = rootView?.absoluteFrame() ?? target.absoluteFrame()
        let endingFrame = target.absoluteFrame()
        
        /// Taking a snapshot is possible because the view is already visible.
        guard let snapshot = target.snapshotView(afterScreenUpdates: true) else {
            assert(false, "Could not get snapshot!")
            context.completeTransition(false)
            return
        }
        
        /// Animation start point.
        target.frame = startingFrame
        galleryView.backgroundColor = .clear
        galleryView.transitionHide()
        target.layer.opacity = transitionOpacity
        
        UIView.animate(
            withDuration: Self.duration,
            delay: .zero,
            options: [.curveEaseInOut],
            animations: {
                /// Animation end point.
                galleryView.backgroundColor = .galleryBackground
                galleryView.transitionShow()
                target.frame = endingFrame
                target.layer.opacity = 1
            },
            completion: { _ in
                context.completeTransition(true)
            }
        )
    }
}

final class GalleryDismissingAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    public static let duration = GalleryPresentingAnimator.duration
    
    private weak var rootView: UIView?
    
    /// Hold reference so `transitioner` is accessible on `interactionControllerForDismissal` method.
    /// Source: https://www.raywenderlich.com/322-custom-uiviewcontroller-transitions-getting-started
    let transitioner: GalleryTransitioner?
    
    init(rootView: UIView?, transitioner: GalleryTransitioner?) {
        self.rootView = rootView
        self.transitioner = transitioner
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Self.duration
    }
    
    func animateTransition(using context: UIViewControllerContextTransitioning) {
        guard let fromView = context.view(forKey: .from) else {
            assert(false, "Could not obtain to view!")
            return
        }
        
        guard let targetProvider = fromView as? GeometryTargetProvider else {
            assert(false, "Missing target provider!")
            context.completeTransition(false)
            return
        }
        
        guard let galleryView = fromView as? GalleryView else {
            assert(false, "Unexpected view type!")
            context.completeTransition(false)
            return
        }
        
        let target: UIView = { /// Place target view into its final position by forcing a layout pass.
            context.containerView.addSubview(galleryView)
            galleryView.constrain(to: context.containerView)
            
            /// Forcing a layout causes the `UICollectionView` to create and display a cell, allowing us to access its contents.
            galleryView.setNeedsLayout()
            context.containerView.layoutIfNeeded()
            
            return targetProvider.targetView
        }()
        
        /// Taking a snapshot is possible because the view is already visible.
        guard let snapshot = target.snapshotView(afterScreenUpdates: false) else {
            assert(false, "Could not get snapshot!")
            context.completeTransition(false)
            return
        }

        /// Ignores `UIScrollView` scaling.
        let startingFrame = CGRect(origin: target.absoluteFrame().origin, size: target.frame.size)
        
        var endingFrame = rootView?.absoluteFrame() ?? target.absoluteFrame()
        endingFrame = scaleCenterFit(startingFrame, into: endingFrame)
        
        /// Hide original.
        target.isHidden = true
        
        /// Animation start point.
        galleryView.backgroundColor = .galleryBackground
        galleryView.transitionShow()
        galleryView.insert(snapshot: snapshot) /// Pass snapshot to view so it can be layered.
        snapshot.frame = startingFrame
        snapshot.layer.opacity = 1
        
        UIView.animate(
            withDuration: Self.duration,
            animations: {
                /// Animation end point.
                galleryView.backgroundColor = .clear
                galleryView.transitionHide()
                snapshot.frame = endingFrame
                snapshot.layer.opacity = transitionOpacity
            },
            completion: { _ in
                snapshot.removeFromSuperview()
                if context.transitionWasCancelled {
                    /// Roll back animation.
                    galleryView.backgroundColor = .galleryBackground
                    galleryView.transitionShow()
                    target.isHidden = false
                    snapshot.frame = startingFrame
                    snapshot.layer.opacity = 1
                    
                    context.completeTransition(false)
                } else {
                    context.completeTransition(true)
                }
            }
        )
    }
}

/// Utility function which scales `rect` down to fit exactly in the center of `frame`.
func scaleCenterFit(_ rect: CGRect, into frame: CGRect) -> CGRect {
    /// - Note: 0.99 accounts for small floating point errors.
    if (rect.size.width / rect.size.height) > (frame.size.width / frame.size.height) {
        /// Rect is proportionally wider than frame, need to center it vertically.
        let scaledHeight = rect.size.height * (frame.size.width / rect.size.width)
        assert(0.99 * scaledHeight <= frame.size.height, "Scaled height should be shorter than frame!")
        let excessHeight = frame.size.height - scaledHeight
        
        return CGRect(
            origin: CGPoint(x: frame.origin.x, y: frame.origin.y + excessHeight / 2),
            size: CGSize(width: frame.size.width, height: scaledHeight)
        )
    } else {
        /// Rect is proportionally taller than frame, need to center it horizontally.
        let scaledWidth = rect.size.width * (frame.size.height / rect.size.height)
        assert(0.99 * scaledWidth <= frame.size.width, "Scaled width \(scaledWidth) should be narrower than frame \(frame.width)!")
        let excessWidth = frame.size.width - scaledWidth

        return CGRect(
            origin: CGPoint(x: frame.origin.x + excessWidth / 2, y: frame.origin.y),
            size: CGSize(width: scaledWidth, height: frame.size.height)
        )
    }
}

final class GalleryTransitioner: UIPercentDrivenInteractiveTransition {
    
    public private(set) var interactionInProgress = false
    
    /// Ranges from 0 when the transition has just begun to 1 when it is complete.
    public private(set) var progress = 0.0

    private var shouldCompleteTransition = false
    private weak var viewController: UIViewController!

    /// How far the transition must go before being rounding up to be completed.
    public static let progressThreshold = 0.5
    
    init(viewController: UIViewController) {
        self.viewController = viewController
        super.init()
        
        /// Create gesture recognizer.
        let gesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handleGesture(_:))
        )
        gesture.cancelsTouchesInView = false
        viewController.view.addGestureRecognizer(gesture)
    }
    
    @objc private func handleGesture(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view!.superview!)
        let distance = sqrt(pow(translation.x, 2) + pow(translation.y, 2))
        self.progress = (distance / 200)
        self.progress = CGFloat(fminf(fmaxf(Float(progress), 0.0), 1.0))
          
        switch gestureRecognizer.state {
            case .began:
                interactionInProgress = true
                viewController.dismiss(animated: true, completion: nil)
            
            case .changed:
                shouldCompleteTransition = progress > Self.progressThreshold
                update(progress)
                
                /// Appearance depends on progress percentage.
                viewController.setNeedsStatusBarAppearanceUpdate()
            
            case .cancelled:
                interactionInProgress = false
                cancel()
            
            case .ended:
                interactionInProgress = false
                if shouldCompleteTransition {
                    finish()
                } else {
                    cancel()
                }
            
            default:
                break
        }
        
        /// - Note: since `interactionInProgress` affects status bar preference, this must be called **afterwards**.
        switch gestureRecognizer.state {
        case .began, .ended, .cancelled:
            viewController.setNeedsStatusBarAppearanceUpdate()
        default:
            break
        }
    }
}
