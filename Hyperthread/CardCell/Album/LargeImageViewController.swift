//
//  LargeImageViewController.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 17/3/22.
//

import UIKit

final class LargeImageViewController: UIViewController {
    
    /// The image's original view.
    /// Knowing this allows us to apply a `matchingGeometry` style effect.
    private weak var rootView: UIView?
    
    private let largeImageView: LargeImageView
    
    private var transitioner: LargeImageTransitioner? = nil
    
    /// When focusing on media, hide the status bar.
    /// A good idea because
    /// - zoomed images will exit the safe area
    /// - the background is black.
    override var prefersStatusBarHidden: Bool { true }
    
    @MainActor
    init(image: UIImage?, rootView: UIView) {
        self.largeImageView = .init(image: image)
        self.rootView = rootView
        super.init(nibName: nil, bundle: nil)
        
        /// Cause modal's preference to take precedent.
        modalPresentationCapturesStatusBarAppearance = true
        
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

protocol SizeAwareView: UIView {
    func didTransition(to size: CGSize) -> Void
}

final class LargeImageView: UIView {
    
    public let frameView: FramedImageView & SizeAwareView

    /// Exists to give us the location of the safeAreaLayoutGuide.
    private let guideView: UIView = .init()
    
    init(image: UIImage?) {
        self.frameView = ZoomableImageView(image: image)
        super.init(frame: .zero)

        addSubview(frameView)
        frameView.translatesAutoresizingMaskIntoConstraints = false
        
        
        #if DEBUG
        let __ENABLE_FRAME_BORDER__ = false
        if __ENABLE_FRAME_BORDER__ {
            frameView.layer.borderWidth = 2
            frameView.layer.borderColor = UIColor.red.cgColor
        }
        #endif
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

/// Some view which fits into our full screen modal layout system.
/// This means it will be subjected to changing constraints during the animation.
/// See `LargeImageView` and associated classes for implementation.
protocol FramedImageView: UIView {
    func setAnimationStartPoint(frame: CGRect) -> Void
    func setAnimationEndPoint(frame: CGRect) -> Void
}
