//
//  ShadeCloseButton.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 23/3/22.
//

import UIKit

final class ShadeCloseButton: UIButton {
    
    private let closeIcon: UIImageView
    
    public weak var closeDelegate: CloseDelegate? = nil
    
    private let config = UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .body))
        .applying(UIImage.SymbolConfiguration(paletteColors: [.galleryUI]))
    
    @MainActor
    init() {
        self.closeIcon = .init(image: UIImage(systemName: "chevron.left", withConfiguration: config))
        super.init(frame: .zero)
        
        addSubview(closeIcon)
        addAction(UIAction(handler: { [weak self] action in
            self?.closeDelegate?.closeGallery()
        }), for: .touchUpInside)
    }
    
    public func constrain(parent: UIView, sibling: UIView, horizontalMargin: CGFloat) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        closeIcon.translatesAutoresizingMaskIntoConstraints = false
        
        /// Constrain visible part to superview, not actual area.
        NSLayoutConstraint.activate([
            closeIcon.leftAnchor.constraint(equalToSystemSpacingAfter: parent.leftAnchor, multiplier: horizontalMargin),
            /// Ensure view covers label.
            closeIcon.bottomAnchor.constraint(equalTo: sibling.bottomAnchor),
            closeIcon.topAnchor.constraint(equalTo: sibling.topAnchor),
        ])
        
        /// Expand hitbox in all directions to provide a generous touch target.
        /// Because this button is in a hard to hit position, it's extra important to be generous.
        NSLayoutConstraint.activate([
            closeIcon.leftAnchor.constraint(equalToSystemSpacingAfter: leftAnchor, multiplier: 2),
            rightAnchor.constraint(equalToSystemSpacingAfter: closeIcon.rightAnchor, multiplier: 2),
            closeIcon.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 2),
            bottomAnchor.constraint(equalToSystemSpacingBelow: closeIcon.bottomAnchor, multiplier: 2),
        ])
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Protocol to send "close this gallery" message.
protocol CloseDelegate: AnyObject {
    @MainActor
    func closeGallery() -> Void
}
