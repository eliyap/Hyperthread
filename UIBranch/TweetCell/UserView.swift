//
//  UserView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 13/11/21.
//

import UIKit
import RealmSwift
import Twig
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
            heightAnchor.constraint(equalTo: widthAnchor)
        ])
        
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

final class UserView: UIStackView {
    
    private let vStack: UIStackView = .init()
    private let profileImage: ProfileImageView = .init()
    private let nameLabel = UILabel()
    private let handleLabel = UILabel()
    fileprivate let _spacing: CGFloat = 5

    /// Combine communication line.
    weak var line: CellEventLine? = nil
    
    /// Track the current User ID.
    private var userID: User.ID? = nil
    
    init(line: CellEventLine? = nil) {
        self.line = line
        super.init(frame: .zero)
        axis = .horizontal
        alignment = .firstBaseline
        spacing = _spacing

        nameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        nameLabel.adjustsFontForContentSizeCategory = true
        
        handleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        handleLabel.adjustsFontForContentSizeCategory = true
        handleLabel.textColor = .secondaryLabel
        
        /// Compress Twitter handle, then long username, but never the symbol!
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        handleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        constrain()
    }
    
    func constrain() -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        
        addArrangedSubview(profileImage)
        NSLayoutConstraint.activate([
            profileImage.heightAnchor.constraint(equalTo: heightAnchor),
        ])
        
        addArrangedSubview(vStack)
        vStack.axis = .vertical
        vStack.alignment = .leading
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.spacing = .zero
        vStack.addArrangedSubview(nameLabel)
        vStack.addArrangedSubview(handleLabel)
        NSLayoutConstraint.activate([
            vStack.heightAnchor.constraint(equalTo: heightAnchor),
        ])
        
        /// Combats the image "as short as possible" preference, avoiding a "crushed" view.
        vStack.setContentCompressionResistancePriority(.required, for: .vertical)
        nameLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        handleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
    }

    public func configure(tweet: Tweet, user: User?, timestamp: Date) {
        self.userID = user?.id
        
        profileImage.configure(user: user)
        
        if let user = user {
            nameLabel.text = user.name
            handleLabel.text = "@" + user.handle
        } else {
            TableLog.error("Received nil user!")
            nameLabel.text = "⚠️ UNKNOWN USER"
            handleLabel.text = "@⚠️"
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        /// Don't count as a cell touch.
//        super.touchesEnded(touches, with: event)
        guard let userID = userID else {
            NetLog.error("Missing User ID on username tap!")
            assert(false)
            return
        }

        line?.events.send(.usernameTouch(userID))
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
