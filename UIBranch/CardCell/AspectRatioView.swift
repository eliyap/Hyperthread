//
//  AspectRatioView.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 28/11/21.
//

import UIKit
import SDWebImage

final class AspectRatioFrameView: UIView {
    
    private let imageView = UIImageView()
    
    /// Allows us to pin the image's height or width to our own.
    private var heightConstraint: NSLayoutConstraint! = nil
    private var widthConstraint: NSLayoutConstraint! = nil
    
    /// Set's the image aspect ratio.
    var aspectRatioConstraint: NSLayoutConstraint! = nil
    
    var imageHeightConstraint: NSLayoutConstraint! = nil
    
    /// Maximum frame aspect ratio.
    private let threshholdAR: CGFloat = 0.667
    
    init() {
        super.init(frame: .zero)
        /// Defuse implicitly unwrapped `nil`s.
        heightConstraint = imageView.heightAnchor.constraint(equalTo: self.heightAnchor)
        widthConstraint = imageView.widthAnchor.constraint(equalTo: self.widthAnchor)
        aspectRatioConstraint = ARConstraint(threshholdAR)
        imageHeightConstraint = heightAnchor.constraint(lessThanOrEqualToConstant: .zero)
        
        addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
    }
    
    func constrain(to view: UIView) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            /// Pin Edges.
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            widthAnchor.constraint(equalTo: view.widthAnchor),
            
            /// Activate custom constraints.
            aspectRatioConstraint,
            imageHeightConstraint,
        ])
        
        /// Using `greatestFiniteMagnitude` triggers "NSLayoutConstraint is being configured with a constant that exceeds internal limits" warning.
        /// Instead, use a height far exceeding any screen in 2021.
        let effectivelyInfinite: CGFloat = 30000
        
        /// Make image and frame "as large as possible".
        let embiggenImage = imageView.heightAnchor.constraint(equalToConstant: effectivelyInfinite)
        embiggenImage.priority = .defaultLow
        let embiggenFrame = heightAnchor.constraint(equalToConstant: effectivelyInfinite)
        embiggenFrame.priority = .defaultLow
        NSLayoutConstraint.activate([embiggenImage, embiggenFrame])
        
        /// Center Image.
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    
    func configure(media: Media) -> Void {
        if let urlString = media.url {
            imageView.sd_setImage(with: URL(string: urlString)) { (image: UIImage?, error: Error?, cacheType: SDImageCacheType, url: URL?) in
                if let error = error {
                    NetLog.warning("Image Loading Error \(error)")
                }
            }
            if media.aspectRatio > self.threshholdAR {
                heightConstraint.isActive = true
                widthConstraint.isActive = false
                replace(object: self, on: \.aspectRatioConstraint, with: ARConstraint(threshholdAR))
            } else {
                heightConstraint.isActive = false
                widthConstraint.isActive = true
                replace(object: self, on: \.aspectRatioConstraint, with: ARConstraint(media.aspectRatio))
            }
            replace(object: self, on: \.imageHeightConstraint, with: heightAnchor.constraint(lessThanOrEqualToConstant: CGFloat(media.height)))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - NSLayoutConstraint Generation
extension AspectRatioFrameView {
    /// Constrain height to be within a certain aspect ratio.
    func ARConstraint(_ aspectRatio: CGFloat) -> NSLayoutConstraint {
        heightAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: aspectRatio)
    }
}

