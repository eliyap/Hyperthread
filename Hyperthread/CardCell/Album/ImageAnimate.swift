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
    
    public let frameView: UIView = .init()

    /// Exists to give us the location of the safeAreaLayoutGuide.
    private let guideView: UIView = .init()
    
    init(url: String) {
        super.init(frame: .zero)

        // DEBUG
        frameView.layer.borderColor = UIColor.red.cgColor
        frameView.layer.borderWidth = 2
        
        addSubview(frameView)
        frameView.translatesAutoresizingMaskIntoConstraints = false
        frameView.addSubview(imageView)

        imageView.sd_setImage(with: URL(string: url), completed: { (image: UIImage?, error: Error?, cacheType: SDImageCacheType, url: URL?) in
            /// Nothing.
        })
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit

        NSLayoutConstraint.activate([
            /// Use `≤`, not `=`, to keep small images at their intrinsic size.
            imageView.widthAnchor.constraint(lessThanOrEqualTo: frameView.widthAnchor),
            imageView.heightAnchor.constraint(lessThanOrEqualTo: frameView.heightAnchor),
            /// Small images default to top leading corner if not centered.
            imageView.centerXAnchor.constraint(equalTo: frameView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: frameView.centerYAnchor),
        ])
    }
    
    /// Constraints active when the view is "at rest", i.e. not animating.
    private var restingConstraints: [NSLayoutConstraint] = []
    public func activateRestingConstraints() -> Void {
        restingConstraints = [
            /// View may exit safe area during animation due to table view offset.
            /// Hence these constraints are temporarily disabled.
            frameView.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            frameView.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            frameView.safeAreaLayoutGuide.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            frameView.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
        ]
        NSLayoutConstraint.activate(restingConstraints)
    }

    public func deactivateRestingConstraints() -> Void {
        NSLayoutConstraint.deactivate(restingConstraints)
        restingConstraints.removeAll()
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
