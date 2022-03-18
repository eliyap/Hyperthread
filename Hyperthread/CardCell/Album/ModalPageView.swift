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
        } else {
            targetIndex = indexPath
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
