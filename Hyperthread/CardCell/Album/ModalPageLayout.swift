//
//  ModalPageLayout.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 18/3/22.
//

import UIKit

final class ModalPageLayout: UICollectionViewFlowLayout {
    @MainActor
    override init() {
        super.init()
        scrollDirection = .horizontal
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
            cell.willTransition(to: newBounds)
        }
        
        return context
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
