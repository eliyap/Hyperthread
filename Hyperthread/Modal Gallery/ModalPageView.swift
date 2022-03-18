//
//  ModalPageView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 18/3/22.
//

import UIKit

final class ModalPageView: UICollectionView {
    
    private let startIndex: IndexPath
    
    /// Flag value for first appearance.
    private var hasSetStartIndex = false
    
    /// Cell index for transition animation target.
    /// Must point to a loaded & visible cell!
    private var targetIndex: IndexPath
    
    @MainActor
    init(startIndex: IndexPath) {
        self.startIndex = startIndex
        self.targetIndex = startIndex
        super.init(frame: .zero, collectionViewLayout: ModalPageLayout())
        
        delegate = self
        isPagingEnabled = true
        register(ModalPageViewCell.self, forCellWithReuseIdentifier: ModalPageViewCell.reuseID)
        backgroundColor = .clear
        
        /// Since pictures can animate into place from outside the safe area,  we need to allow out-of-bounds pixels to be shown.
        clipsToBounds = false
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
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        /// Reset zoom when cell disappears, similar to iOS's Photos.
        /// - Note: do *not* perform in `willDisplay`, as this interferes with the `contentSize` correction calculated during device rotation.
        guard let cell = cell as? ModalPageViewCell else {
            assert(false, "Incorrect type!")
            return
        }
        cell.resetDisplay()
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

/// Update current index for animation when scrolling.
extension ModalPageView: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let target = getCurrentIndexPath() else { return }
        targetIndex = target
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard let target = getCurrentIndexPath() else { return }
        targetIndex = target
    }
}

extension ModalPageView {
    /// Obtains a single index path by checking the view's center.
    /// Source: https://stackoverflow.com/a/24396643/12395667
    func getCurrentIndexPath() -> IndexPath? {
        let visibleRect = CGRect(origin: contentOffset, size: bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        let visibleIndexPath = indexPathForItem(at: visiblePoint)
        return visibleIndexPath
    }
}

extension ModalPageView: GeometryTargetProvider {
    var targetView: UIView {
        guard let target = cellForItem(at: targetIndex) as? GeometryTargetProvider else {
            assert(false, "Could not get target!")
            return self
        }
        return target.targetView
    }
}
