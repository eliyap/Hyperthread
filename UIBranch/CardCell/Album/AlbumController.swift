//
//  PageViewController.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 5/12/21.
//

import UIKit

class AlbumController: UIPageViewController {
    
    public var controllers: [ImageViewController] = []
    
    /// Constrains the view's height to below some aspect ratio.
    /// Value is subject to change.
    private var aspectRatioConstraint: NSLayoutConstraint? = nil
    
    /// Constrains the album to the largest intrinsic media height so small images aren't black-barred.
    private var intrinsicHeightConstraint: NSLayoutConstraint? = nil
    
    /// Maximum frame aspect ratio, so that tall images don't stretch the cell.
    private let threshholdAR: CGFloat = 0.667
    
    private let countButton: UIButton
    
    private let _delegate = FakePageDelegate()
    
    private static var countButtonConfig: UIButton.Configuration = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .systemGray6
        config.cornerStyle = .capsule
        config.titleTextAttributesTransformer = .init { incoming in
            var outgoing = incoming
            outgoing.foregroundColor = .label
            outgoing.font = .preferredFont(forTextStyle: .footnote)
            return outgoing
        }
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
        return config
    }()
    
    init() {
        self.countButton = UIButton(configuration: Self.countButtonConfig, primaryAction: nil)
        
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        
        let superTall = view.heightAnchor.constraint(equalToConstant: 30000)
        superTall.isActive = true
        superTall.priority = .defaultLow
        
        /// Disable paging dots, as we re-use components and there is no good way to update the page count.
        delegate = _delegate
        dataSource = self
        
        view.addSubview(countButton)
        view.bringSubviewToFront(countButton)
        countButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            countButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -CardTeaserCell.borderInset),
            countButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -CardTeaserCell.borderInset),
        ])
        
        countButton.adjustsImageSizeForAccessibilityContentSizeCategory = true
    }
    
    public func configure(tweet: Tweet) -> Void {
        if tweet.media.isNotEmpty {
            let maxAR = tweet.media.map(\.aspectRatio).max()!
            let maxHeight = CGFloat(tweet.media.map(\.height).max()!)
            replace(object: self, on: \.aspectRatioConstraint, with: ARConstraint(min(threshholdAR, maxAR)))
            replace(object: self, on: \.intrinsicHeightConstraint, with: view.heightAnchor.constraint(lessThanOrEqualToConstant: maxHeight))
            
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
                countButton.isHidden = false
                countButton.setTitle("1/\(tweet.media.count)", for: .normal)
            } else {
                dataSource = nil
                countButton.isHidden = true
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
