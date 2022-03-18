//
//  ModalPageViewCell.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 18/3/22.
//

import UIKit

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
