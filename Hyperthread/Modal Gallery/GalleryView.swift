//
//  GalleryView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 18/3/22.
//

import UIKit

final class GalleryView: UIView {
    
    private weak var pageView: ModalPageView!
    private let topShade: TopShadeView
    
    public weak var closeDelegate: CloseDelegate? = nil
    
    init(pageView: ModalPageView) {
        self.pageView = pageView
        self.topShade = .init()
        super.init(frame: .zero)
        
        topShade.closeDelegate = self
        
        addSubview(pageView)
        addSubview(topShade)
    }
    
    /// Called by superview.
    public func constrain(to view: UIView) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        pageView.constrain(to: self)
        topShade.constrain(to: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension GalleryView: CloseDelegate {
    func closeGallery() {
        closeDelegate?.closeGallery()
    }
}

extension GalleryView: GeometryTargetProvider {
    var targetView: UIView {
        pageView.targetView
    }
}

final class TopShadeView: UIStackView {
    
    private let closeButton: CloseButton
    private let countLabel: UILabel
    
    public weak var closeDelegate: CloseDelegate? = nil
    
    @MainActor
    init() {
        self.closeButton = .init()
        self.countLabel = .init()
        super.init(frame: .zero)
        
        backgroundColor = .galleryBackground.withAlphaComponent(0.6)
        
        addSubview(closeButton)
        closeButton.closeDelegate = self
        
        addSubview(countLabel)
        
        countLabel.text = "–/–"
        countLabel.textColor = .galleryUI
        countLabel.font = UIFont.preferredFont(forTextStyle: .body)
        countLabel.adjustsFontForContentSizeCategory = true
    }
    
    /// Called by superview.
    public func constrain(to view: UIView) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            /// Full width, ignoring safe area in iPhone landscape.
            leftAnchor.constraint(equalTo: view.leftAnchor),
            rightAnchor.constraint(equalTo: view.rightAnchor),
            topAnchor.constraint(equalTo: view.topAnchor),
        ])
        
        let horizontalMargin = 1.5
        
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rightAnchor.constraint(equalToSystemSpacingAfter: countLabel.rightAnchor, multiplier: horizontalMargin),
            /// Ensure view covers label.
            bottomAnchor.constraint(equalToSystemSpacingBelow: countLabel.bottomAnchor, multiplier: 1),
            countLabel.topAnchor.constraint(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 0.5),
        ])
        
        closeButton.constrain(to: self, horizontalMargin: horizontalMargin)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { /** Deliberately ignore event. **/ }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { /** Deliberately ignore event. **/ }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { /** Deliberately ignore event. **/ }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension TopShadeView: CloseDelegate {
    func closeGallery() {
        closeDelegate?.closeGallery()
    }
}

final class CloseButton: UIButton {
    
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
    
    public func constrain(to view: UIView, horizontalMargin: CGFloat) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        closeIcon.translatesAutoresizingMaskIntoConstraints = false
        
        /// Constrain visible part to superview, not actual area.
        NSLayoutConstraint.activate([
            closeIcon.leftAnchor.constraint(equalToSystemSpacingAfter: view.leftAnchor, multiplier: horizontalMargin),
            /// Ensure view covers label.
            view.bottomAnchor.constraint(equalToSystemSpacingBelow: closeIcon.bottomAnchor, multiplier: 1),
            closeIcon.topAnchor.constraint(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 0.5),
        ])
        
        /// Expand hitbox in all directions to provide a generous touch target.
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

protocol CloseDelegate: AnyObject {
    @MainActor
    func closeGallery() -> Void
}
