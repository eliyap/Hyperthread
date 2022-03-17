//
//  PageViewController.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 5/12/21.
//

import UIKit

class AlbumController: UIPageViewController {
    
    /// Contains **displayed** media controllers.
    public var controllers: [MediaViewController] = []
    
    /// Contains recycled view controllers, and spawns new ones.
    fileprivate let controllerArchive: OwnedArchive<MediaViewController> = .init(makeView: MediaViewController.init)
    
    /// Constrains the view's height to below some aspect ratio.
    /// Value is subject to change.
    private var aspectRatioConstraint: NSLayoutConstraint? = nil
    
    /// Constrains the album to the largest intrinsic media height so small images aren't black-barred.
    private var intrinsicHeightConstraint: NSLayoutConstraint? = nil
    
    /// Maximum frame aspect ratio, so that tall images don't stretch the cell.
    private let threshholdAR: CGFloat = 1.333
    
    /// Displays the total number of images, and the one you're currently on.
    /// e.g. `1/4`.
    private let countButton: UIButton
    
    /// The upcoming page number.
    private var pendingIndex: Int = 1
        
    private static let CountButtonInset: CGFloat = 6
    
    @MainActor
    init() {
        self.countButton = CountButton()
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        
        let superTall = view.heightAnchor.constraint(equalToConstant: .superTall)
        superTall.isActive = true
        superTall.priority = .defaultLow
        
        /// Disable paging dots, as we re-use components and there is no good way to update the page count.
        delegate = self
        dataSource = self
        
        view.addSubview(countButton)
        view.bringSubviewToFront(countButton)
        countButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            countButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -AlbumController.CountButtonInset),
            countButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -AlbumController.CountButtonInset),
        ])
    }
    
    public func configure(tweet: Tweet) -> Void {
        configure(media: Array(tweet.media), picUrlString: tweet.picUrlString)
    }
    
    /// - Note: allowing us to pass "no media" fixes issue where `superTall` dimensions cause bad layout.
    public func configure(media: [Media], picUrlString: String?) -> Void {
        if media.isNotEmpty {
            let maxAR = media.map(\.aspectRatio).max()!
            let maxHeight = CGFloat(media.map(\.height).max()!)
            replace(object: self, on: \.aspectRatioConstraint, with: ARConstraint(min(threshholdAR, maxAR)))
            replace(object: self, on: \.intrinsicHeightConstraint, with: view.heightAnchor.constraint(lessThanOrEqualToConstant: maxHeight))
            
            /// Archive old views.
            for controller in controllers {
                controller.view.removeFromSuperview()
                controllerArchive.archive(controller)
            }
            controllers = []
            
            /// Get new views from archive.
            for mediaItem in media {
                let mediaController = controllerArchive.unarchive()
                mediaController.configure(media: mediaItem, picUrlString: picUrlString, presentModalAlbum: { [weak self] in
                    self?.presentModalAlbum()
                })
                controllers.append(mediaController)
            }
            
            view.isHidden = false
            presentFirst()
            
            /** Credit: https://stackoverflow.com/a/24847685/12395667
             *  Removing the data source "prevents scrolling" as a logical (if unintuitive) consequence.
             *  - Subview diving to set `isScrollEnabled` to `false` is risky and undocumented.
             *  - `isUserInteractionEnabled` would prevent tap gestures.
             */
            if media.count > 1 {
                dataSource = self
                countButton.isHidden = false
                countButton.setTitle("1/\(media.count)", for: .normal)
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
        guard let mediaController = viewController as? MediaViewController else {
            fatalError("Unexpected type!")
        }
        guard let index = controllers.firstIndex(of: mediaController), index > 0 else { return nil }
        return controllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let mediaController = viewController as? MediaViewController else {
            fatalError("Unexpected type!")
        }
        guard let index = controllers.firstIndex(of: mediaController), index < controllers.count - 1 else { return nil }
        return controllers[index + 1]
    }
    
    /// Acknowledge existence of paging dots, but deliberately disable them.
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    /// Acknowledge existence of paging dots, but deliberately disable them.
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
}

extension AlbumController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard pendingViewControllers.count == 1, let pending = pendingViewControllers.first else {
            assert(false, "Unexpected controller count!")
            return
        }
        guard let mediaController = pending as? MediaViewController else {
            assert(false, "Unexpected Type!")
            return
        }
        guard let index = controllers.firstIndex(of: mediaController) else {
            assert(false, "Could not locate pending controller!")
            return
        }
        pendingIndex = index + 1
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard finished && completed else { return }
        
        /// Update page number.
        countButton.setTitle("\(pendingIndex)/\(controllers.count)", for: .normal)
    }
}

/// A structure that stores re-usable elements, to avoid re-initializing them frequently.
fileprivate final class OwnedArchive<Item: AnyObject> {
    /// > If your array’s Element type is a class or @objc protocol and
    /// > you do not need to bridge the array to NSArray or pass the array to Objective-C APIs,
    /// > using `ContiguousArray` may be more efficient and have more predictable performance than `Array`.
    /// Docs: https://developer.apple.com/documentation/swift/contiguousarray
    private var views: ContiguousArray<Item> = []
    
    /// Factory method for when the archives run out.
    private let makeItem: @MainActor () -> Item
    
    init(makeView: @escaping @MainActor () -> Item) {
        self.makeItem = makeView
    }
    
    func archive(_ view: Item) -> Void {
        views.append(view)
    }
    
    @MainActor
    func unarchive() -> Item {
        if views.isNotEmpty {
            return views.removeLast()
        } else {
            return makeItem()
        }
    }
}

extension AlbumController {
    func presentModalAlbum() -> Void {
        let modal = LargeImageViewController(image: nil, rootView: view)
        guard let root = view.window?.rootViewController else {
            assert(false, "Could not obtain root view controller!")
            return
        }
        root.present(modal, animated: true, completion: {
            /// Nothing.
        })
        /// Nothing...
    }
}
