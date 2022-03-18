//
//  PageView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 17/3/22.
//

import UIKit

final class ModalPageViewController: UIViewController {
    
    private let pageView: ModalPageView
    
    public typealias Cell = ModalPageViewCell
    
    private let dataSource: ModalAlbumDataSource
    
    private weak var rootView: UIView?
    
    private var transitioner: LargeImageTransitioner? = nil
    
    private let startIndex: IndexPath
    
    init(images: [UIImage?], rootView: UIView, startIndex: Int) {
        self.rootView = rootView
        self.pageView = .init(rootView: rootView, image: images.first ?? nil)
        self.dataSource = .init(collectionView: pageView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cell.reuseID, for: indexPath) as? Cell else {
                fatalError("Failed to create or cast new cell!")
            }
            
            let image: UIImage? = images[indexPath.item]
            cell.configure(image: image)
            
            return cell
        })
        self.startIndex = .init(item: startIndex, section: 0)
        super.init(nibName: nil, bundle: nil)
        
        view = pageView
        pageView.dataSource = dataSource
        
        var snapshot: ModalAlbumDataSource.Snapshot = .init()
        snapshot.appendSections([.all])
        snapshot.appendItems(Array(0..<images.count), toSection: .all)
        dataSource.apply(snapshot)
        
        /// Request a custom animation.
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }
    
    /// Conflicting reports on what works, try a couple points as a failsafe.
    /// https://stackoverflow.com/questions/18087073/start-uicollectionview-at-a-specific-indexpath
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setStartIndex()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setStartIndex()
    }
    func setStartIndex() -> Void {
//        pageView.scrollToItem(at: startIndex, at: [], animated: false)
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

final class ModalPageView: UICollectionView {
    
    public weak var rootView: UIView?
    
    public let previewImage: UIImage?
    
    @MainActor
    init(rootView: UIView, image: UIImage?) {
        self.previewImage = image
        self.rootView = rootView
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        super.init(frame: .zero, collectionViewLayout: layout)
        
        delegate = self
        isPagingEnabled = true
        register(ModalPageViewCell.self, forCellWithReuseIdentifier: ModalPageViewCell.reuseID)
        
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
            topAnchor.constraint(equalTo: view.topAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    func didCompletePresentation() -> Void {
    
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    private let zoomableImageView: _ZoomableImageView
    
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
        
        // DEBUG
        self.backgroundColor = .blue
    }
    
    public func configure(image: UIImage?) -> Void {
        zoomableImageView.configure(image: image)
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

extension ModalPageViewController: UIViewControllerTransitioningDelegate {
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
        guard let pageView = toView as? ModalPageView else {
            assert(false, "Unexpected view type!")
            context.completeTransition(false)
            return
        }
        context.containerView.addSubview(pageView)
        pageView.constrain(to: context.containerView)
        pageView.setNeedsLayout()
        context.containerView.layoutIfNeeded()
        
        guard let cell = pageView.cellForItem(at: startIndex) as? ModalPageViewCell else {
            assert(false, "Could not get cell!")
            context.completeTransition(false)
            return
        }
        
        print(cell.targetView.absoluteFrame())
        
        /// Send to animation end point.
        /// Constraint animation: https://stackoverflow.com/questions/12926566/are-nslayoutconstraints-animatable
        UIView.animate(
            withDuration: Self.duration,
            animations: {
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