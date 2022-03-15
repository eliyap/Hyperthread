//
//  ImageAnimate.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 6/12/21.
//

import UIKit
import SDWebImage

final class LargeImageViewController: UIViewController {
    
    private let startingFrame: CGRect
    
    private let largeImageView: LargeImageView
    
    private var transitioner: LargeImageTransitioner? = nil
    
    @MainActor
    init(url: String, startingFrame: CGRect) {
        self.largeImageView = .init(url: url)
        self.startingFrame = startingFrame
        super.init(nibName: nil, bundle: nil)
        
        view = largeImageView
        
        transitioner = LargeImageTransitioner(viewController: self)
        
        /// Request a custom animation.
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class LargeImageView: UIView {
    
    public let imageView: UIImageView = .init()
    
    init(url: String) {
        super.init(frame: .zero)
        
        addSubview(imageView)
        imageView.sd_setImage(with: URL(string: url), completed: { (image: UIImage?, error: Error?, cacheType: SDImageCacheType, url: URL?) in
            /// Nothing.
        })
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit

        #warning("TODO: fix layout constraints here.")
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor),
            imageView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor),
        ])
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
        return ImageDismissingAnimator(startingFrame: startingFrame, transitioner: transitioner)
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard
            let animator = animator as? ImageDismissingAnimator,
            let transitioner = animator.transitioner,
            transitioner.interactionInProgress
        else {
          return nil
        }
        return transitioner
    }
}

final class LargeImageTransitioner: UIPercentDrivenInteractiveTransition {
    
    var interactionInProgress = false

    private var shouldCompleteTransition = false
    private weak var viewController: UIViewController!

    init(viewController: UIViewController) {
        super.init()
        self.viewController = viewController
        prepareGestureRecognizer(in: viewController.view)
    }
    
    private func prepareGestureRecognizer(in view: UIView) {
        let gesture = UIScreenEdgePanGestureRecognizer(
            target: self,
            action: #selector(handleGesture(_:))
        )
        gesture.edges = .left
        view.addGestureRecognizer(gesture)
    }
    
    @objc func handleGesture(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view!.superview!)
        var progress = (translation.x / 200)
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
