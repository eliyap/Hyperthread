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
    
    private let placeholder: UIImage? = .init(
        systemName: "person.crop.circle",
        withConfiguration: UIImage.SymbolConfiguration(hierarchicalColor: .tertiarySystemBackground)
    )
    
    init() {
        self.imageView = .init(image: placeholder)
        super.init(frame: .zero)
        addSubview(imageView)
        
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
        
        imageView.sd_setImage(with: imageUrl, placeholderImage: placeholder) { [weak self] (image: UIImage?, error: Error?, cacheType: SDImageCacheType, url: URL?) in
            if let error = error {
                NetLog.warning("Image Loading Error \(error)")
            }
            if image == nil {
                NetLog.error("Failed to load image! \(#file)")
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class UserView: UIStackView {
    
    private let symbolButton = UIButton()
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

        translatesAutoresizingMaskIntoConstraints = false
        
        addArrangedSubview(symbolButton)
        addArrangedSubview(nameLabel)
        addArrangedSubview(handleLabel)

        nameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        nameLabel.adjustsFontForContentSizeCategory = true
        
        handleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        handleLabel.adjustsFontForContentSizeCategory = true
        handleLabel.textColor = .secondaryLabel
        
        /// Compress Twitter handle, then long username, but never the symbol!
        symbolButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        handleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        /// Configure Symbol.
        var config = UIImage.SymbolConfiguration.init(paletteColors: [.secondaryLabel])
        config = config.applying(UIImage.SymbolConfiguration(textStyle: .headline))
        symbolButton.setPreferredSymbolConfiguration(config, forImageIn: .normal)
    }

    public func configure(tweet: Tweet, user: User?, timestamp: Date) {
        self.userID = user?.id
        
        if let user = user {
            nameLabel.text = user.name
            handleLabel.text = "@" + user.handle
        } else {
            TableLog.error("Received nil user!")
            nameLabel.text = "⚠️ UNKNOWN USER"
            handleLabel.text = "@⚠️"
        }
        
        switch tweet.primaryReferenceType {
        case .replied_to:
            symbolButton.isHidden = false
            symbolButton.setImage(UIImage(systemName: ReplySymbol.name), for: .normal)
        case .quoted:
            symbolButton.isHidden = false
            symbolButton.setImage(UIImage(systemName: QuoteSymbol.name), for: .normal)
        default:
            symbolButton.isHidden = true
            
            /// Placeholder image prevents height shrinking to zero, which leads to graphical glitches.
            symbolButton.setImage(UIImage(systemName: "circle"), for: .normal)
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
