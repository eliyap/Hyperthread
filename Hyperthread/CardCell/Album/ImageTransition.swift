//
//  ImageTransition.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 15/3/22.
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
        
        largeImageView.frame = context.containerView.frame
        
        /// Set animation start point.
        let startingFrame: CGRect = rootView?.absoluteFrame() ?? .zero
        largeImageView.backgroundColor = .clear
        let widthConstraint = largeImageView.matchView.widthAnchor.constraint(equalToConstant: startingFrame.width)
        let heightConstraint = largeImageView.matchView.heightAnchor.constraint(equalToConstant: startingFrame.height)
        let xConstraint = largeImageView.matchView.leadingAnchor.constraint(equalTo: largeImageView.leadingAnchor, constant: startingFrame.origin.x)
        let yConstraint = largeImageView.matchView.topAnchor.constraint(equalTo: largeImageView.topAnchor, constant: startingFrame.origin.y)
        NSLayoutConstraint.activate([widthConstraint, heightConstraint, xConstraint, yConstraint])
        
        /// - Note: important that we lay out the superview, so that the offset constraints affect layout!
        largeImageView.layoutIfNeeded()

        largeImageView.matchView.setNeedsUpdateConstraints()

        /// Send to animation end point.
        /// Constraint animation: https://stackoverflow.com/questions/12926566/are-nslayoutconstraints-animatable
        UIView.animate(
            withDuration: Self.duration,
            animations: {
                largeImageView.backgroundColor = .galleryBackground

                widthConstraint.constant = context.containerView.frame.width
                heightConstraint.constant = context.containerView.frame.height
                xConstraint.constant = 0
                yConstraint.constant = 0
                largeImageView.layoutIfNeeded()
            },
            completion: { _ in
                widthConstraint.isActive = false
                heightConstraint.isActive = false
                xConstraint.isActive = false
                yConstraint.isActive = false

                largeImageView.activateRestingConstraints()

                context.completeTransition(true)
            }
        )
    }
}

final class ImageDismissingAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    public static let duration = ImagePresentingAnimator.duration
    
    private weak var rootView: UIView?
    
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
        context.containerView.addSubview(largeImageView)
                
        largeImageView.frame = context.containerView.frame
        largeImageView.deactivateRestingConstraints()

        /// Set animation start point.
        largeImageView.backgroundColor = .galleryBackground
        largeImageView.imageView.frame = CGRect(origin: .zero, size: context.containerView.frame.size)
        let widthConstraint = largeImageView.matchView.widthAnchor.constraint(equalToConstant: context.containerView.frame.width)
        let heightConstraint = largeImageView.matchView.heightAnchor.constraint(equalToConstant: context.containerView.frame.height)
        let xConstraint = largeImageView.matchView.leadingAnchor.constraint(equalTo: largeImageView.leadingAnchor, constant: context.containerView.frame.origin.x)
        let yConstraint = largeImageView.matchView.topAnchor.constraint(equalTo: largeImageView.topAnchor, constant: context.containerView.frame.origin.y)
        NSLayoutConstraint.activate([widthConstraint, heightConstraint, xConstraint, yConstraint])
        
        /// - Note: important that we lay out the superview, so that the offset constraints affect layout!
        largeImageView.layoutIfNeeded()

        largeImageView.matchView.setNeedsUpdateConstraints()

        /// Send to animation end point.
        /// Constraint animation: https://stackoverflow.com/questions/12926566/are-nslayoutconstraints-animatable
        UIView.animate(
            withDuration: Self.duration,
            animations: { [weak self] in
                let frame = self?.rootView?.absoluteFrame() ?? .zero
                largeImageView.imageView.frame = CGRect(origin: CGPoint(x: 1, y: 1), size: context.containerView.frame.size)
                largeImageView.backgroundColor = .clear

                widthConstraint.constant = frame.width
                heightConstraint.constant = frame.height
                xConstraint.constant = frame.origin.x
                yConstraint.constant = frame.origin.y
                largeImageView.layoutIfNeeded()
            },
            completion: { _ in
                /// Remove animation constraints.
                widthConstraint.isActive = false
                heightConstraint.isActive = false
                xConstraint.isActive = false
                yConstraint.isActive = false
                
                if context.transitionWasCancelled {
                    /// Set background back to opaque.
                    largeImageView.backgroundColor = .galleryBackground

                    /// Reset constraints.
                    largeImageView.activateRestingConstraints()
                    
                    context.completeTransition(false)
                } else {
                    context.completeTransition(true)
                }
            }
        )
    }
}
