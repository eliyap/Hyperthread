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
    
    @MainActor
    init(url: String, startingFrame: CGRect) {
        self.largeImageView = .init(url: url)
        self.startingFrame = startingFrame
        super.init(nibName: nil, bundle: nil)
        
        view = largeImageView
        
        
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
        return ImageDismissingAnimator(startingFrame: startingFrame)
    }
}
