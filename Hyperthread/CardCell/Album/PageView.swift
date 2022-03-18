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

extension GalleryView: GeometryTargetProvider {
    var targetView: UIView {
        pageView.targetView
    }
}

enum AlbumSection: Hashable {
    case all
}

final class ModalAlbumDataSource: UICollectionViewDiffableDataSource<AlbumSection, Int> {
    public typealias Snapshot = NSDiffableDataSourceSnapshot<AlbumSection, Int>
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

extension GalleryViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return AlbumPresentingAnimator(rootView: rootView)
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
    
    init(rootView: UIView?) {
        self.rootView = rootView
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
        
        guard let targetProvider = toView as? GeometryTargetProvider else {
            assert(false, "Missing target provider!")
            context.completeTransition(false)
            return
        }
        
        guard let galleryView = toView as? GalleryView else {
            assert(false, "Unexpected view type!")
            context.completeTransition(false)
            return
        }
        
        let target: UIView = { /// Place target view into its final position by forcing a layout pass.
            context.containerView.addSubview(galleryView)
            galleryView.constrain(to: context.containerView)
            
            /// Forcing a layout causes the `UICollectionView` to create and display a cell, allowing us to access its contents.
            galleryView.setNeedsLayout()
            context.containerView.layoutIfNeeded()
            
            return targetProvider.targetView
        }()
        
        let startingFrame = rootView?.absoluteFrame() ?? target.absoluteFrame()
        let endingFrame = target.absoluteFrame()
        
        /// Animation start point.
        target.frame = startingFrame
        galleryView.backgroundColor = .clear
        
        UIView.animate(
            withDuration: Self.duration,
            animations: {
                /// Animation end point.
                galleryView.backgroundColor = .galleryBackground
                target.frame = endingFrame
            },
            completion: { _ in
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
        
        guard let targetProvider = fromView as? GeometryTargetProvider else {
            assert(false, "Missing target provider!")
            context.completeTransition(false)
            return
        }
        
        guard let galleryView = fromView as? GalleryView else {
            assert(false, "Unexpected view type!")
            context.completeTransition(false)
            return
        }
        
        let target: UIView = { /// Place target view into its final position by forcing a layout pass.
            context.containerView.addSubview(galleryView)
            galleryView.constrain(to: context.containerView)
            
            /// Forcing a layout causes the `UICollectionView` to create and display a cell, allowing us to access its contents.
            galleryView.setNeedsLayout()
            context.containerView.layoutIfNeeded()
            
            return targetProvider.targetView
        }()
        
        let startingFrame = target.absoluteFrame()
        let endingFrame = rootView?.absoluteFrame() ?? target.absoluteFrame()
        
        /// Animation start point.
        galleryView.backgroundColor = .galleryBackground
        target.frame = startingFrame
        
        UIView.animate(
            withDuration: Self.duration,
            animations: {
                /// Animation end point.
                galleryView.backgroundColor = .clear
                target.frame = endingFrame
            },
            completion: { _ in
                if context.transitionWasCancelled {
                    context.completeTransition(false)
                } else {
                    context.completeTransition(true)
                }
            }
        )
    }
}
