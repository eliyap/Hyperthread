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
    public static let cornerRadius: CGFloat = 6
    
    private let placeholder: UIImage? = .init(
        systemName: "person.crop.circle",
        withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .quaternaryLabel)
    )
    
    @MainActor
    init() {
        self.imageView = .init(image: placeholder)
        super.init(frame: .zero)
        addSubview(imageView)
        
        imageView.layer.cornerRadius = Self.cornerRadius
        imageView.layer.cornerCurve = .continuous
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        
        constrain()
    }
    
    public static let maxSize: CGFloat = 100
    private func constrain() -> Void {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        /// Ensure an image aspect ratio of 1.
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
        ])
        
        /// Pin image bounds to view bounds.
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: widthAnchor),
            
            /// Allow view to be taller than square image, accomodating tall text views
            /// (e.g. multiple lines with large dynamic type).
            imageView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor),
            imageView.heightAnchor.constraint(lessThanOrEqualToConstant: Self.maxSize),
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
