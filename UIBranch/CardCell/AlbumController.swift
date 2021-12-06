//
//  PageViewController.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 5/12/21.
//

import UIKit
import SDWebImage

class AlbumController: UIPageViewController {
    
    var controllers: [ImageViewController] = []
    
    /// Constrains the view's height to below some aspect ratio.
    /// Value is subject to change.
    var aspectRatioConstraint: NSLayoutConstraint! = nil
    
    /// Maximum frame aspect ratio, so that tall images don't stretch the cell.
    private let threshholdAR: CGFloat = 0.667
    
    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        
        /// Defuse implicitly unwrapped `nil`s.
        aspectRatioConstraint = ARConstraint(threshholdAR)
        
        let superTall = view.heightAnchor.constraint(equalToConstant: 30000)
        superTall.isActive = true
        superTall.priority = .defaultLow
        
        delegate = self
        dataSource = self
    }
    
    public func configure(tweet: Tweet) -> Void {
        if tweet.media.isNotEmpty {
            let maxAR = tweet.media.map(\.aspectRatio).max()!
            replace(object: self, on: \.aspectRatioConstraint, with: ARConstraint(min(threshholdAR, maxAR)))
            
            /// Discard old views, just in case.
            controllers.forEach { $0.view.removeFromSuperview() }
            
            /// Get new views.
            controllers = Array(tweet.media).map { media in
                let vc = ImageViewController()
                vc.configure(media: media)
                vc.view.backgroundColor = .flat
                return vc
            }
            
            view.isHidden = false
            presentFirst()
            
            /** Credit: https://stackoverflow.com/a/24847685/12395667
             *  Removing the data source "prevents scrolling" as a logical (if unintuitive) consequence.
             *  - Subview diving to set `isScrollEnabled` to `false` is risky and undocumented.
             *  - `isUserInteractionEnabled` would prevent tap gestures.
             */
            if tweet.media.count > 1 {
                dataSource = self
            } else {
                dataSource = nil
            }
        } else {
            view.isHidden = true
        }
    }
    
    private func presentFirst() -> Void {
        guard let first = controllers.first else {
            assert(false, "Failed to get first controller!")
            return
        }
        setViewControllers([first], direction: .forward, animated: false, completion: nil)
    }
    
    /// Constrain height to be within a certain aspect ratio.
    private func ARConstraint(_ aspectRatio: CGFloat) -> NSLayoutConstraint {
        view.heightAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: aspectRatio)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AlbumController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let imageController = viewController as? ImageViewController else {
            fatalError("Unexpected type!")
        }
        guard let index = controllers.firstIndex(of: imageController), index > 0 else { return nil }
        return controllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let imageController = viewController as? ImageViewController else {
            fatalError("Unexpected type!")
        }
        guard let index = controllers.firstIndex(of: imageController), index < controllers.count - 1 else { return nil }
        return controllers[index + 1]
    }
}

extension AlbumController: UIPageViewControllerDelegate {
    
    /** Paging Dots deliberately disabled.
        We re-use these components and there is no good way to update the count.
     */
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
}

final class ImageViewController: UIViewController {
    
    private let imageView = UIImageView()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        /// Make image as tall as possible.
        /// Using `greatestFiniteMagnitude` triggers "NSLayoutConstraint is being configured with a constant that exceeds internal limits" warning.
        /// Instead, use a height far exceeding any screen in 2021.
        let superTall = imageView.heightAnchor.constraint(equalToConstant: 30000)
        superTall.isActive = true
        superTall.priority = .defaultLow
        
        /// Constrain image height.
        imageView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor).isActive = true
    }
    
    func configure(media: Media) -> Void {
        if let urlString = media.url {
            imageView.sd_setImage(with: URL(string: urlString)) { (image: UIImage?, error: Error?, cacheType: SDImageCacheType, url: URL?) in
                if let error = error {
                    NetLog.warning("Image Loading Error \(error)")
                }
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        TableLog.debug("\(Self.description()) de-initialized", print: true, false)
    }
}
