//
//  GalleryTransition.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 18/3/22.
//

import UIKit

/// Views pop above navigation bars when animated in, we reduce transparency to make that less jarring.
let transitionOpacity: Float = 0.25

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
        
        /// Animation start point.
        target.frame = startingFrame
        galleryView.backgroundColor = .clear
        target.layer.opacity = transitionOpacity
        
        UIView.animate(
            withDuration: Self.duration,
            delay: .zero,
            options: [.curveEaseInOut],
            animations: {
                /// Animation end point.
                galleryView.backgroundColor = .galleryBackground
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

        /// Additionally, we must use container coordinates, as the target view has scaling and offset applied by the scrollview.
        context.containerView.addSubview(snapshot)
        
        /// Ignores `UIScrollView` scaling.
        let startingFrame = CGRect(origin: target.absoluteFrame().origin, size: target.frame.size)
        
        var endingFrame = rootView?.absoluteFrame() ?? target.absoluteFrame()
        endingFrame = scaleCenterFit(startingFrame, into: endingFrame)
        
        /// Hide original.
        target.isHidden = true
        
        /// Animation start point.
        galleryView.backgroundColor = .galleryBackground
        snapshot.frame = startingFrame
        snapshot.layer.opacity = 1
        
        UIView.animate(
            withDuration: Self.duration,
            animations: {
                /// Animation end point.
                galleryView.backgroundColor = .clear
                snapshot.frame = endingFrame
                snapshot.layer.opacity = transitionOpacity
            },
            completion: { _ in
                snapshot.removeFromSuperview()
                if context.transitionWasCancelled {
                    /// Roll back animation.
                    galleryView.backgroundColor = .galleryBackground
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
    
    var interactionInProgress = false

    private var shouldCompleteTransition = false
    private weak var viewController: UIViewController!

    init(viewController: UIViewController) {
        self.viewController = viewController
        super.init()
        
        /// Create gesture recognizer.
        let gesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handleGesture(_:))
        )
        viewController.view.addGestureRecognizer(gesture)
    }
    
    @objc private func handleGesture(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view!.superview!)
        let distance = sqrt(pow(translation.x, 2) + pow(translation.y, 2))
        var progress = (distance / 200)
        progress = CGFloat(fminf(fmaxf(Float(progress), 0.0), 1.0))
          
        switch gestureRecognizer.state {
            case .began:
                interactionInProgress = true
                viewController.dismiss(animated: true, completion: nil)
            
            case .changed:
                shouldCompleteTransition = progress > 0.5
                update(progress)
            
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
    }
}
