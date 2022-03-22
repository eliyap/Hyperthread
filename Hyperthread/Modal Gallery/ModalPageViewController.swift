//
//  ModalPageViewController.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 18/3/22.
//

import UIKit

final class ModalPageViewController: UIViewController {
    
    public let pageView: ModalPageView
    
    public typealias Cell = ModalPageViewCell
    
    private let dataSource: ModalAlbumDataSource
    
    /// Delegates.
    public weak var imageVisionDelegate: ImageVisionDelegate? = nil
    
    init(images: [UIImage?], startIndex: IndexPath, imageVisionDelegate: ImageVisionDelegate) {
        self.pageView = .init(startIndex: startIndex)
        self.dataSource = .init(collectionView: pageView, cellProvider: { collectionView, indexPath, itemIdentifier in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Cell.reuseID, for: indexPath) as? Cell else {
                fatalError("Failed to create or cast new cell!")
            }
            
            let image: UIImage? = images[indexPath.item]
            cell.configure(image: image, frame: collectionView.safeAreaLayoutGuide.layoutFrame)
            cell.imageVisionDelegate = imageVisionDelegate
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            /// 22.03.18
            /// Fixes wrong item size after resizing multitasking on iPadOS.
            /// Despite other invalidation methods being in place, this fixed the issue.
            /// Breaks layout when rotating iPhone, hence conditionally included.
            pageView.collectionViewLayout.invalidateLayout()
        }

        /// On rotation, reset cell to 1x zoom, to prevent bad layout.
        for cell in pageView.visibleCells {
            guard let cell = cell as? ModalPageViewCell else {
                assert(false, "Unexpected cell type \(type(of: cell))")
                continue
            }
            cell.resetDisplay()
            cell.willTransition(to: size)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ModalPageViewController: ImageVisionDelegate {
    func didReport(progress: Double) -> Void {
        imageVisionDelegate?.didReport(progress: progress)
    }
}

extension ModalPageViewController: TextRequestDelegate {
    func didRequestText() {
        pageView.didRequestText()
    }
}
