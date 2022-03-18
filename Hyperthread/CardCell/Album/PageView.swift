//
//  PageView.swift
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
    
    private var transitioner: LargeImageTransitioner? = nil
    
    private let startIndex: IndexPath
    
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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class GalleryView: UIView {
    
    weak var pageView: ModalPageView!
    
    init(pageView: ModalPageView) {
        self.pageView = pageView
        super.init(frame: .zero)
    }
    
    func constrain(to view: UIView) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        pageView.constrain(to: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

enum AlbumSection: Hashable {
    case all
}

final class ModalAlbumDataSource: UICollectionViewDiffableDataSource<AlbumSection, Int> {
    public typealias Snapshot = NSDiffableDataSourceSnapshot<AlbumSection, Int>
}

final class ModalPageLayout: UICollectionViewFlowLayout {
    @MainActor
    override init() {
        super.init()
        scrollDirection = .horizontal
        
        print("auto size\(self.estimatedItemSize == Self.automaticSize)")
    }
    
    /// - Note: called when scrolling view, do not be over-zealous about invalidating.
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if collectionView?.bounds.size != newBounds.size {
            return true
        } else {
            return super.shouldInvalidateLayout(forBoundsChange: newBounds)
        }
    }
    
    /// Adapted from: https://medium.com/@ilabs/a-simple-guide-to-adjust-uicollectionview-to-device-rotation-8704093c2abe
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        guard
            let context = context as? UICollectionViewFlowLayoutInvalidationContext,
            let collectionView = self.collectionView
        else { return context }
        
        let oldBounds = collectionView.bounds
        
        /// Request recalculation of cell sizes.
        context.invalidateFlowLayoutDelegateMetrics = (oldBounds.size != newBounds.size)
        
        context.contentSizeAdjustment = CGSize(
            width: (newBounds.size.width - oldBounds.size.width) * CGFloat(collectionView.numberOfItems(inSection: 0)),
            height: newBounds.size.height - oldBounds.size.height
        )
        
        for item in 0..<collectionView.numberOfItems(inSection: 0) {
            guard let cell = collectionView.cellForItem(at: IndexPath(item: item, section: 0)) as? ModalPageViewCell else {
                /// Cells may not be loaded / visible yet, so it is normal to fail here.
                continue
            }
            
            /// - Important: Relies on `collectionView.bounds` being equal to image frame bounds.
            cell.zoomableImageView.predictInsets(size: newBounds.size)
        }
        
        return context
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ModalPageViewController: UIViewController {
    
    public let pageView: ModalPageView
    
    public typealias Cell = ModalPageViewCell
    
    private let dataSource: ModalAlbumDataSource
    
    init(images: [UIImage?], startIndex: IndexPath) {
        self.pageView = .init(startIndex: startIndex)
        self.dataSource = .init(collectionView: pageView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cell.reuseID, for: indexPath) as? Cell else {
                fatalError("Failed to create or cast new cell!")
            }
            
            let image: UIImage? = images[indexPath.item]
            cell.configure(image: image, frame: collectionView.safeAreaLayoutGuide.layoutFrame)
            
            return cell
        })
        super.init(nibName: nil, bundle: nil)
        
        view = pageView
        pageView.dataSource = dataSource
        
        var snapshot: ModalAlbumDataSource.Snapshot = .init()
        snapshot.appendSections([.all])
        snapshot.appendItems(Array(0..<images.count), toSection: .all)
        dataSource.apply(snapshot)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ModalPageView: UICollectionView {
    
    private let startIndex: IndexPath
    
    /// Flag value for first appearance.
    private var hasSetStartIndex = false
    
    @MainActor
    init(startIndex: IndexPath) {
        self.startIndex = startIndex
        super.init(frame: .zero, collectionViewLayout: ModalPageLayout())
        
        delegate = self
        isPagingEnabled = true
        register(ModalPageViewCell.self, forCellWithReuseIdentifier: ModalPageViewCell.reuseID)
        backgroundColor = .clear
        
        #if DEBUG
        let __ENABLE_FRAME_BORDER__ = true
        if __ENABLE_FRAME_BORDER__ {
            layer.borderWidth = 2
            layer.borderColor = UIColor.red.cgColor
        }
        #endif
    }
    
    func constrain(to view: UIView) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ModalPageView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if hasSetStartIndex == false {
            scrollToItem(at: startIndex, at: [], animated: false)
            hasSetStartIndex = true
        }
    }
}

extension ModalPageView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        /// Request full size pages.
        frame.size
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        /// Removes page spacing.
        .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, minimumLineSpacingForSectionAt: Int) -> CGFloat {
        /// Removes page spacing.
        .zero
    }
}

final class ModalPageViewCell: UICollectionViewCell {
    
    public static let reuseID = "ModalPageViewCell"
    
    public let zoomableImageView: _ZoomableImageView
    
    @MainActor
    override init(frame: CGRect) {
        self.zoomableImageView = .init()
        super.init(frame: .zero)
        
        addSubview(zoomableImageView)
        zoomableImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            zoomableImageView.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            zoomableImageView.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            zoomableImageView.safeAreaLayoutGuide.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            zoomableImageView.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
        ])
    }
    
    public func configure(image: UIImage?, frame: CGRect) -> Void {
        zoomableImageView.configure(image: image, frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ModalPageViewCell: GeometryTargetProvider {
    var targetView: UIView {
        zoomableImageView.targetView
    }
}

extension GalleryViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AlbumPresentingAnimator(rootView: rootView, startIndex: startIndex)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AlbumDismissingAnimator(rootView: rootView, transitioner: transitioner)
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

final class AlbumPresentingAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    public static let duration = 0.25
    
    private weak var rootView: UIView?
    
    private let startIndex: IndexPath
    
    init(rootView: UIView?, startIndex: IndexPath) {
        self.rootView = rootView
        self.startIndex = startIndex
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Self.duration
    }
    
    func animateTransition(using context: UIViewControllerContextTransitioning) {
        guard let toView = context.view(forKey: .to) else {
            assert(false, "Could not obtain originating views!")
            context.completeTransition(false)
            return
        }
        guard let galleryView = toView as? GalleryView else {
            assert(false, "Unexpected view type!")
            context.completeTransition(false)
            return
        }
        
        { /// Place target view into its final position by forcing a layout pass.
            context.containerView.addSubview(galleryView)
            galleryView.constrain(to: context.containerView)
            galleryView.setNeedsLayout()
            context.containerView.layoutIfNeeded()
            
            guard let cell = pageView.cellForItem(at: startIndex) as? ModalPageViewCell else {
                assert(false, "Could not get cell!")
                context.completeTransition(false)
                return
            }
        }()
        
        /// Animate fade down.
        galleryView.backgroundColor = .clear
        galleryView.pageView.isHidden = true
        UIView.animate(
            withDuration: Self.duration,
            animations: { galleryView.backgroundColor = .galleryBackground },
            completion: { _ in
                galleryView.pageView.isHidden = false
                context.completeTransition(true)
            }
        )
    }
}

final class AlbumDismissingAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    public static let duration = ImagePresentingAnimator.duration
    
    private weak var rootView: UIView?
    
    /// Hold reference so `transitioner` is accessible on `interactionControllerForDismissal` method.
    /// Source: https://www.raywenderlich.com/322-custom-uiviewcontroller-transitions-getting-started
    let transitioner: LargeImageTransitioner?
    
    init(rootView: UIView?, transitioner: LargeImageTransitioner?) {
        self.rootView = rootView
        self.transitioner = transitioner
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Self.duration
    }
    
    func animateTransition(using context: UIViewControllerContextTransitioning) {
        guard let fromView = context.view(forKey: .from) else {
            assert(false, "Could not obtain to view!")
            return
        }
        guard let largeImageView = fromView as? LargeImageView else {
            assert(false, "Unexpected view type!")
            context.completeTransition(false)
            return
        }
        
        let startingFrame: CGRect = context.containerView.safeAreaLayoutGuide.layoutFrame
        let endingFrame: CGRect = rootView?.absoluteFrame() ?? .zero
        
        /// Deactivate before temporary constraints are activated, or we face a conflict.
        context.containerView.addSubview(largeImageView)
        largeImageView.deactivateRestingConstraints()
        
        largeImageView.frame = context.containerView.frame
        
        /// Set animation start point.
        largeImageView.backgroundColor = .galleryBackground
        let widthConstraint = largeImageView.frameView.widthAnchor.constraint(equalToConstant: startingFrame.width)
        let heightConstraint = largeImageView.frameView.heightAnchor.constraint(equalToConstant: startingFrame.height)
        let xConstraint = largeImageView.frameView.leadingAnchor.constraint(equalTo: largeImageView.leadingAnchor, constant: startingFrame.origin.x)
        let yConstraint = largeImageView.frameView.topAnchor.constraint(equalTo: largeImageView.topAnchor, constant: startingFrame.origin.y)
        NSLayoutConstraint.activate([widthConstraint, heightConstraint, xConstraint, yConstraint])
        
        /// - Note: important that we lay out the superview, so that the offset constraints affect layout!
        /// - Note: `setAnimationStartPoint` must come after layout pass to get accuate dimensions.
        largeImageView.layoutIfNeeded()
        largeImageView.frameView.setAnimationStartPoint(frame: startingFrame)
        
        largeImageView.frameView.setNeedsUpdateConstraints()

        /// Set another animation start point.
        largeImageView.frameView.layer.opacity = 1.0
        
        /// Send to animation end point.
        /// Constraint animation: https://stackoverflow.com/questions/12926566/are-nslayoutconstraints-animatable
        UIView.animate(
            withDuration: Self.duration,
            animations: {
                largeImageView.backgroundColor = .clear
                
                widthConstraint.constant = endingFrame.width
                heightConstraint.constant = endingFrame.height
                xConstraint.constant = endingFrame.origin.x
                yConstraint.constant = endingFrame.origin.y
                largeImageView.layoutIfNeeded()
                
                /// - Note: `setAnimationEndPoint` must come after layout pass to get accuate dimensions.
                largeImageView.frameView.setAnimationEndPoint(frame: endingFrame)
                
                /// Slowly fade down the image, so that when it overlaps with the navigation bar,
                /// the "pop" disappearance is less jarring.
                largeImageView.frameView.layer.opacity = 0.25
            },
            completion: { _ in
                /// Remove animation constraints.
                NSLayoutConstraint.deactivate([widthConstraint, heightConstraint, xConstraint, yConstraint])
                
                if context.transitionWasCancelled {
                    largeImageView.frameView.layer.opacity = 1.0
                    
                    /// Set background back to opaque.
                    largeImageView.backgroundColor = .galleryBackground
                    
                    /// Reactivate constraints.
                    largeImageView.activateRestingConstraints()
                    
                    /// Reset frame.
                    largeImageView.frameView.setAnimationStartPoint(frame: startingFrame)

                    context.completeTransition(false)
                } else {
                    context.completeTransition(true)
                }
            }
        )
    }
}
