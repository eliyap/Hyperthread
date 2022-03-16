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
        guard let toView = toView as? LargeImageView else {
            assert(false, "Unexpected view type!")
            context.completeTransition(false)
            return
        }
        context.containerView.addSubview(toView)
        
        /// Set animation start point.
        let startingFrame: CGRect = rootView?.absoluteFrame() ?? .zero
        toView.frame = startingFrame
        toView.imageView.frame = CGRect(origin: .zero, size: startingFrame.size)
        toView.backgroundColor = .clear
        
        /// Send to animation end point.
        UIView.animate(
            withDuration: Self.duration,
            animations: {
                toView.frame = context.containerView.frame
                toView.imageView.frame = CGRect(origin: .zero, size: context.containerView.frame.size)
                toView.backgroundColor = .galleryBackground
            },
            completion: { _ in
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
        guard let fromView = fromView as? LargeImageView else {
            assert(false, "Unexpected view type!")
            context.completeTransition(false)
            return
        }
        context.containerView.addSubview(fromView)
                
        /// Set animation start point.
        fromView.backgroundColor = .galleryBackground
        fromView.frame = context.containerView.frame
        fromView.imageView.frame = CGRect(origin: .zero, size: context.containerView.frame.size)
        
        /// Send to animation end point.
        UIView.animate(
            withDuration: Self.duration,
            animations: { [weak self] in
                let frame = self?.rootView?.absoluteFrame() ?? .zero
                fromView.frame = frame
                fromView.imageView.frame = CGRect(origin: .zero, size: frame.size)
                fromView.backgroundColor = .clear
            },
            completion: { _ in
                if context.transitionWasCancelled {
                    /// Set background back to opaque.
                    fromView.backgroundColor = .galleryBackground
                    
                    context.completeTransition(false)
                } else {
                    context.completeTransition(true)
                }
            }
        )
    }
}
