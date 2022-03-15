//
//  ImageAnimate.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 6/12/21.
//

import UIKit
import SDWebImage

final class ImagePresentingAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let duration = 0.25
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using context: UIViewControllerContextTransitioning) {
        guard let toView = context.view(forKey: .to) else {
            assert(false, "Could not obtain to view!")
            return
        }
        context.containerView.addSubview(toView)
        toView.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
        UIView.animate(
            withDuration: duration,
            animations: {
                toView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            },
            completion: { _ in
                context.completeTransition(true)
            }
        )
        
    }
}

final class ImageDismissingAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let duration = 0.25
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using context: UIViewControllerContextTransitioning) {
        guard let fromView = context.view(forKey: .from) else {
            assert(false, "Could not obtain to view!")
            return
        }
        context.containerView.addSubview(fromView)
        fromView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        UIView.animate(
            withDuration: duration,
            animations: {
                /// Note: using `.leastNonZeroMagnitude` or `.zero` seems to case some optimization and removes the view instantly.
                /// 0.001 is large enough that the animation can happen correctly.
                fromView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            },
            completion: { _ in
                context.completeTransition(true)
            }
        )
    }
}


final class LargeImageViewController: UIViewController {
    
    private var imageView: UIImageView = .init()
    
    @MainActor
    init(url: String) {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        
        view.backgroundColor = .systemRed
        view.addSubview(imageView)
        imageView.sd_setImage(with: URL(string: url), completed: { (image: UIImage?, error: Error?, cacheType: SDImageCacheType, url: URL?) in
            /// Nothing.
        })
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor),
        ])
        
        /// Request a custom animation.
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LargeImageViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ImagePresentingAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ImageDismissingAnimator()
    }
}
