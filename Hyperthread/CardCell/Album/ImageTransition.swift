//
//  ImageTransition.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 15/3/22.
//

import UIKit

final class ImagePresentingAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    public static let duration = 2.5
    
    private let startingFrame: CGRect
    
    init(startingFrame: CGRect) {
        self.startingFrame = startingFrame
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
        
        /// Add initially transparent view to create "fade to black" effect.
        let bgView = UIView()
        bgView.backgroundColor = .clear
        bgView.frame = context.containerView.frame
        context.containerView.insertSubview(bgView, at: 0)
        
        /// Set animation start point.
        toView.frame = startingFrame
        toView.imageView.frame = CGRect(origin: .zero, size: startingFrame.size)
        
        /// Send to animation end point.
        UIView.animate(
            withDuration: Self.duration,
            animations: {
                toView.frame = context.containerView.frame
                toView.imageView.frame = CGRect(origin: .zero, size: context.containerView.frame.size)
                bgView.backgroundColor = .black
            },
            completion: { _ in
                /// Let view take over the cover.
                toView.backgroundColor = .black
                
                bgView.removeFromSuperview()
                context.completeTransition(true)
            }
        )
    }
}

final class ImageDismissingAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let duration = 0.25
    
    private let startingFrame: CGRect
    
    init(startingFrame: CGRect) {
        self.startingFrame = startingFrame
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
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
        
        /// Add initially opaque view to create "fade from black" effect.
        let bgView = UIView()
        bgView.backgroundColor = .black
        bgView.frame = context.containerView.frame
        context.containerView.insertSubview(bgView, at: 0)
        
        /// Remove modal background color, which would interfere.
        fromView.backgroundColor = .clear
        
        /// Set animation start point.
        fromView.frame = context.containerView.frame
        fromView.imageView.frame = CGRect(origin: .zero, size: context.containerView.frame.size)
        
        /// Send to animation end point.
        UIView.animate(
            withDuration: duration,
            animations: { [weak self] in
                let frame = self?.startingFrame ?? .zero
                fromView.frame = frame
                fromView.imageView.frame = CGRect(origin: .zero, size: frame.size)
                bgView.backgroundColor = .clear
            },
            completion: { _ in
                bgView.removeFromSuperview()
                context.completeTransition(true)
            }
        )
    }
}
