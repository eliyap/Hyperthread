//
//  ImageAnimate.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 6/12/21.
//

import UIKit
import SDWebImage

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
        context.containerView.addSubview(toView)
        
        toView.frame = startingFrame
        UIView.animate(
            withDuration: Self.duration,
            animations: {
                toView.frame = context.containerView.frame
            },
            completion: { _ in
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
        context.containerView.addSubview(fromView)
        fromView.frame = context.containerView.frame
        UIView.animate(
            withDuration: duration,
            animations: { [weak self] in
                let frame = self?.startingFrame ?? .zero
                fromView.frame = frame
            },
            completion: { _ in
                context.completeTransition(true)
            }
        )
    }
}


final class LargeImageViewController: UIViewController {
    
    private var imageView: UIImageView = .init()
    
    private let startingFrame: CGRect
    
    @MainActor
    init(url: String, startingFrame: CGRect) {
        self.startingFrame = startingFrame
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        
        view.backgroundColor = .systemRed
//        view.addSubview(imageView)
//        imageView.sd_setImage(with: URL(string: url), completed: { (image: UIImage?, error: Error?, cacheType: SDImageCacheType, url: URL?) in
//            /// Nothing.
//        })
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        imageView.contentMode = .scaleAspectFit
//
//        #warning("TODO: fix layout constraints here.")
//        NSLayoutConstraint.activate([
//            imageView.widthAnchor.constraint(equalTo: view.widthAnchor),
//        ])
        
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
        return ImagePresentingAnimator(startingFrame: startingFrame)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ImageDismissingAnimator(startingFrame: startingFrame)
    }
}
