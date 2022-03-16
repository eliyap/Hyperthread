//
//  ImageAnimate.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 6/12/21.
//

import UIKit
import SDWebImage

final class LargeImageViewController: UIViewController {
    
    /// The image's original view.
    /// Knowing this allows us to apply a `matchingGeometry` style effect.
    private weak var rootView: UIView?
    
    private let largeImageView: LargeImageView
    
    private var transitioner: LargeImageTransitioner? = nil
    
    @MainActor
    init(url: String, rootView: UIView) {
        self.largeImageView = .init(url: url)
        self.rootView = rootView
        super.init(nibName: nil, bundle: nil)
        
        view = largeImageView
        
        transitioner = LargeImageTransitioner(viewController: self)
        
        /// Request a custom animation.
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        view.frame = .init(origin: .zero, size: size)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LargeImageViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ImagePresentingAnimator(rootView: rootView)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ImageDismissingAnimator(rootView: rootView, transitioner: transitioner)
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

final class LargeImageView: UIView {
    
    public let imageView: UIImageView = .init()
    
    public let matchView: UIView = .init()

    init(url: String) {
        super.init(frame: .zero)

        matchView.layer.borderColor = UIColor.green.cgColor
        matchView.layer.borderWidth = 2

        addSubview(matchView)
        matchView.translatesAutoresizingMaskIntoConstraints = false
        matchView.addSubview(imageView)

        // addSubview(imageView)
        imageView.sd_setImage(with: URL(string: url), completed: { (image: UIImage?, error: Error?, cacheType: SDImageCacheType, url: URL?) in
            /// Nothing.
        })
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit

        #warning("TODO: fix layout constraints here.")
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(lessThanOrEqualTo: matchView.widthAnchor),
            imageView.heightAnchor.constraint(lessThanOrEqualTo: matchView.heightAnchor),
        ])
    }
    
    /// Constraints active "at rest", i.e. not animating.
    var matchWidthConstraint: NSLayoutConstraint? = nil
    var matchHeightConstraint: NSLayoutConstraint? = nil
    var matchXConstraint: NSLayoutConstraint? = nil
    var matchYConstraint: NSLayoutConstraint? = nil
    public func activateRestingConstraints() -> Void { 
        matchWidthConstraint = matchView.widthAnchor.constraint(equalTo: widthAnchor)
        matchHeightConstraint = matchView.heightAnchor.constraint(equalTo: heightAnchor)
        matchXConstraint = matchView.centerXAnchor.constraint(equalTo: centerXAnchor)
        matchYConstraint = matchView.centerYAnchor.constraint(equalTo: centerYAnchor)
        
        matchWidthConstraint?.isActive = true
        matchHeightConstraint?.isActive = true
        matchXConstraint?.isActive = true
        matchYConstraint?.isActive = true
    }

    public func deactivateRestingConstraints() -> Void {
        matchWidthConstraint?.isActive = false
        matchHeightConstraint?.isActive = false
        matchXConstraint?.isActive = false
        matchYConstraint?.isActive = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class LargeImageTransitioner: UIPercentDrivenInteractiveTransition {
    
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
