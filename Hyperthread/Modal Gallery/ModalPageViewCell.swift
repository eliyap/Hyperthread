//
//  ModalPageViewCell.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 18/3/22.
//

import UIKit

final class ModalPageViewCell: UICollectionViewCell {
    
    public static let reuseID = "ModalPageViewCell"
    
    private let zoomableImageView: ZoomableImageView
    
    /// Delegates.
    public weak var imageVisionDelegate: ImageVisionDelegate? = nil
    
    @MainActor
    override init(frame: CGRect) {
        self.zoomableImageView = .init()
        super.init(frame: .zero)
        
        addSubview(zoomableImageView)
        zoomableImageView.translatesAutoresizingMaskIntoConstraints = false

        /// - Important: must be coordinated with superview constraints!
        if UIDevice.current.userInterfaceIdiom == .pad {
            /// Fixes layout popping due to sudden appearnce of status bar on iPad when dismissing modal.
            /// Ignore safe areas, since iPads are effectively rectangular (less corners, but that hardly matters).
            /// Assumes no iPads have notches.
            NSLayoutConstraint.activate([
                zoomableImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
                zoomableImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
                zoomableImageView.topAnchor.constraint(equalTo: topAnchor),
                zoomableImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        } else { /// Assume iPhone.
            /// Be extra careful with iPhones, where the notch is large.
            NSLayoutConstraint.activate([
                zoomableImageView.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
                zoomableImageView.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
                zoomableImageView.safeAreaLayoutGuide.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
                zoomableImageView.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            ])
        }
        
        zoomableImageView.imageVisionDelegate = self
    }
    
    public func configure(image: UIImage?, frame: CGRect) -> Void {
        zoomableImageView.configure(image: image, frame: frame)
    }
    
    /// - Note: non-standard function, not part of `UIView` API.
    public func willTransition(to size: CGSize) -> Void {
        zoomableImageView.predictInsets(size: size)
    }
    
    public func resetDisplay() -> Void {
        zoomableImageView.zoomScale = 1
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

extension ModalPageViewCell: ImageVisionDelegate {
    func didReport(progress: Double) -> Void {
        imageVisionDelegate?.didReport(progress: progress)
    }
}
