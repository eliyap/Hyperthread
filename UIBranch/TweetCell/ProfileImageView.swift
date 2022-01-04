//
//  ProfileImageView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 3/1/22.
//

import Foundation
import UIKit
import SDWebImage

final class ProfileImageView: UIView {
    
    private let imageView: UIImageView
    
    /// Make sure corner radii compose nicely.
    public class var cornerRadius: CGFloat { CardBackground.cornerRadius - CardBackground.inset }
    
    private let placeholder: UIImage? = .init(
        systemName: "person.crop.circle",
        withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .quaternaryLabel)
    )
    
    init() {
        self.imageView = .init(image: placeholder)
        super.init(frame: .zero)
        addSubview(imageView)
        
        imageView.layer.cornerRadius = Self.cornerRadius
        imageView.layer.cornerCurve = .continuous
        imageView.clipsToBounds = true
        
        constrain()
    }
    
    private func constrain() -> Void {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        /// Ensure an aspect ratio of 1.
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalTo: widthAnchor),
        ])
        
        /// Pin image bounds to view bounds.
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.heightAnchor.constraint(equalTo: heightAnchor),
            imageView.widthAnchor.constraint(equalTo: widthAnchor),
        ])

        /// Request for view to be "as short as possible".
        let imageShort = imageView.heightAnchor.constraint(equalToConstant: .zero)
        imageShort.priority = .defaultHigh
        imageShort.isActive = true
        
        let selfShort = self.heightAnchor.constraint(equalToConstant: .zero)
        selfShort.priority = .defaultHigh
        selfShort.isActive = true
    }
    
    func configure(user: User?) -> Void {
        guard let user = user else {
            imageView.image = nil
            return
        }
        
        guard let imageUrl = user.resolvedProfileImageUrl else {
            ModelLog.warning("Could not resolve profile image url for User \(user)")
            return
        }
        
        imageView.sd_setImage(with: imageUrl, placeholderImage: placeholder) { (image: UIImage?, error: Error?, cacheType: SDImageCacheType, url: URL?) in
            if let error = error, error.isOfflineError == false {
                NetLog.warning("Image Loading Error \(error)")
            }
            if image == nil {
                if let error = error, error.isOfflineError {
                    /** Do nothing. **/
                } else {
                    NetLog.warning("Failed to load image! \(#file)")
                }
                
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
