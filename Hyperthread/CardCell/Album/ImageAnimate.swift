//
//  ImageAnimate.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 6/12/21.
//

import UIKit

public extension UIColor {
    /// Similar to iOS's Photos App, use a "dark room" style black background for image galleries.
    static let galleryBackground: UIColor = .black
}

final class ImagePresentingAnimator: NSObject, UIViewControllerAnimatedTransitioning {
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
        guard let largeImageView = toView as? LargeImageView else {
            assert(false, "Unexpected view type!")
            context.completeTransition(false)
            return
        }
        context.containerView.addSubview(largeImageView)
        
        /// Deactivate before temporary constraints are activated, or we face a conflict.
        largeImageView.frame = context.containerView.frame
        largeImageView.deactivateRestingConstraints()
        
        /// - Note: do not use `largeImageView` frame as it is periodically incorrect since layout is in flux.
        let startingFrame: CGRect = rootView?.absoluteFrame() ?? .zero
        let endingFrame: CGRect = context.containerView.safeAreaLayoutGuide.layoutFrame
        
        /// Set animation start point.
        largeImageView.backgroundColor = .clear
        let widthConstraint = largeImageView.frameView.widthAnchor.constraint(equalToConstant: startingFrame.width)
        let heightConstraint = largeImageView.frameView.heightAnchor.constraint(equalToConstant: startingFrame.height)
        let xConstraint = largeImageView.frameView.leadingAnchor.constraint(equalTo: largeImageView.leadingAnchor, constant: startingFrame.origin.x)
        let yConstraint = largeImageView.frameView.topAnchor.constraint(equalTo: largeImageView.topAnchor, constant: startingFrame.origin.y)
        NSLayoutConstraint.activate([widthConstraint, heightConstraint, xConstraint, yConstraint])
        
        /// - Note: important that we lay out the superview, so that the offset constraints affect layout!
        /// - Note: `setAnimationStartPoint` must come after layout pass to get accuate dimensions.
        largeImageView.layoutIfNeeded()
        largeImageView.frameView.setAnimationStartPoint(frame: startingFrame)
        
        largeImageView.frameView.setNeedsUpdateConstraints()

        /// Send to animation end point.
        /// Constraint animation: https://stackoverflow.com/questions/12926566/are-nslayoutconstraints-animatable
        UIView.animate(
            withDuration: Self.duration,
            animations: {
                largeImageView.backgroundColor = .galleryBackground
                
                widthConstraint.constant = endingFrame.width
                heightConstraint.constant = endingFrame.height
                xConstraint.constant = endingFrame.origin.x
                yConstraint.constant = endingFrame.origin.y
                largeImageView.layoutIfNeeded()
                
                /// - Note: `setAnimationEndPoint` must come after layout pass to get accuate dimensions.
                largeImageView.frameView.setAnimationEndPoint(frame: endingFrame)
            },
            completion: { _ in
                NSLayoutConstraint.deactivate([widthConstraint, heightConstraint, xConstraint, yConstraint])
                largeImageView.activateRestingConstraints()

                context.completeTransition(true)
            }
        )
    }
}

final class ImageDismissingAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    public static let duration = ImagePresentingAnimator.duration
    
    private weak var rootView: UIView?
    
    /// Hold reference so `transitioner` is accessible on `interactionControllerForDismissal` method.
    /// Source: https://www.raywenderlich.com/322-custom-uiviewcontroller-transitions-getting-started
    let transitioner: LargeImageTransitioner?
    
    init(rootView: UIView?, transitioner: LargeImageTransitioner?) {
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
        guard let largeImageView = fromView as? LargeImageView else {
            assert(false, "Unexpected view type!")
            context.completeTransition(false)
            return
        }
        
        let startingFrame: CGRect = context.containerView.safeAreaLayoutGuide.layoutFrame
        let endingFrame: CGRect = rootView?.absoluteFrame() ?? .zero
        
        /// Deactivate before temporary constraints are activated, or we face a conflict.
        context.containerView.addSubview(largeImageView)
        largeImageView.deactivateRestingConstraints()
        
        largeImageView.frame = context.containerView.frame
        
        /// Set animation start point.
        largeImageView.backgroundColor = .galleryBackground
        let widthConstraint = largeImageView.frameView.widthAnchor.constraint(equalToConstant: startingFrame.width)
        let heightConstraint = largeImageView.frameView.heightAnchor.constraint(equalToConstant: startingFrame.height)
        let xConstraint = largeImageView.frameView.leadingAnchor.constraint(equalTo: largeImageView.leadingAnchor, constant: startingFrame.origin.x)
        let yConstraint = largeImageView.frameView.topAnchor.constraint(equalTo: largeImageView.topAnchor, constant: startingFrame.origin.y)
        largeImageView.frameView.setAnimationStartPoint(frame: startingFrame)
        NSLayoutConstraint.activate([widthConstraint, heightConstraint, xConstraint, yConstraint])
        
        /// - Note: important that we lay out the superview, so that the offset constraints affect layout!
        largeImageView.layoutIfNeeded()

        largeImageView.frameView.setNeedsUpdateConstraints()

        /// Set another animation start point.
        largeImageView.frameView.layer.opacity = 1.0
        
        /// Send to animation end point.
        /// Constraint animation: https://stackoverflow.com/questions/12926566/are-nslayoutconstraints-animatable
        UIView.animate(
            withDuration: Self.duration,
            animations: {
                largeImageView.backgroundColor = .clear
                largeImageView.frameView.setAnimationEndPoint(frame: endingFrame)
                
                widthConstraint.constant = endingFrame.width
                heightConstraint.constant = endingFrame.height
                xConstraint.constant = endingFrame.origin.x
                yConstraint.constant = endingFrame.origin.y
                largeImageView.layoutIfNeeded()
                
                /// Slowly fade down the image, so that when it overlaps with the navigation bar,
                /// the "pop" disappearance is less jarring.
                largeImageView.frameView.layer.opacity = 0.25
            },
            completion: { _ in
                /// Remove animation constraints.
                NSLayoutConstraint.deactivate([widthConstraint, heightConstraint, xConstraint, yConstraint])
                
                if context.transitionWasCancelled {
                    largeImageView.frameView.layer.opacity = 1.0
                    
                    /// Set background back to opaque.
                    largeImageView.backgroundColor = .galleryBackground
                    
                    /// Reactivate constraints.
                    largeImageView.activateRestingConstraints()
                    
                    /// Reset frame.
                    largeImageView.frameView.setAnimationStartPoint(frame: startingFrame)

                    context.completeTransition(false)
                } else {
                    context.completeTransition(true)
                }
            }
        )
    }
}
