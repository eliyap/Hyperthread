//
//  ImageAnimate.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 6/12/21.
//

import UIKit

extension AlbumController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.mode = .presenting
        return animator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        animator.mode = .dismissing
        return animator
    }
}

final class AlbumAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    public enum Mode { case presenting, dismissing }
    private let duration = 0.25
    public var mode: Mode = .presenting
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

final class LargeImageViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        
        view.backgroundColor = .systemRed
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
