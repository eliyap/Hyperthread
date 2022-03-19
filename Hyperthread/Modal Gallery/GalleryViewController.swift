//
//  GalleryViewController.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 17/3/22.
//

import UIKit

final class GalleryViewController: UIViewController {
    
    private let galleryView: GalleryView
    
    private let pageViewController: ModalPageViewController
    
    public typealias Cell = ModalPageViewCell
    
    private weak var rootView: UIView?
    
    private var transitioner: GalleryTransitioner? = nil
    
    private let startIndex: IndexPath
    
    /// Don't want images going under status bar.
    override var prefersStatusBarHidden: Bool {
        if let transitioner = transitioner {
            return transitioner.interactionInProgress == false
        } else {
            return true
        }
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { .fade }
    
    init(images: [UIImage?], rootView: UIView, startIndex: Int) {
        self.rootView = rootView
        let startIndex = IndexPath(item: startIndex, section: 0)
        self.startIndex = startIndex
        let pageViewController = ModalPageViewController(images: images, startIndex: startIndex)
        self.pageViewController = pageViewController
        self.galleryView = .init(pageView: pageViewController.pageView)
        super.init(nibName: nil, bundle: nil)
        
        view = galleryView
        
        addChild(pageViewController)
        galleryView.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        
        /// Request a custom animation.
        modalPresentationStyle = .custom
        transitioningDelegate = self
        transitioner = GalleryTransitioner(viewController: self)
        
        /// Take control of status bar.
        /// Docs: https://developer.apple.com/documentation/uikit/uiviewcontroller/1621453-modalpresentationcapturesstatusb
        modalPresentationCapturesStatusBarAppearance = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension GalleryViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return GalleryPresentingAnimator(rootView: rootView)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return GalleryDismissingAnimator(rootView: rootView, transitioner: transitioner)
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard
            let animator = animator as? GalleryDismissingAnimator,
            let transitioner = animator.transitioner,
            transitioner.interactionInProgress
        else {
          return nil
        }
        return transitioner
    }
}
