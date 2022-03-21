//
//  TopShadeView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 20/3/22.
//

import UIKit

final class TopShadeView: UIView {
    
    private let closeButton: CloseButton
    private let countLabel: UILabel
    private let imageCount: Int
    
    public weak var closeDelegate: CloseDelegate? = nil
    
    @MainActor
    init(imageCount: Int, startIndex: Int) {
        self.closeButton = .init()
        self.countLabel = .init()
        self.imageCount = imageCount
        super.init(frame: .zero)
        
        backgroundColor = .galleryShade
        
        addSubview(closeButton)
        closeButton.closeDelegate = self
        
        addSubview(countLabel)
        
        countLabel.text = "–/–"
        countLabel.textColor = .galleryUI
        countLabel.font = UIFont.preferredFont(forTextStyle: .body)
        countLabel.adjustsFontForContentSizeCategory = true
        if imageCount == 1 {
            countLabel.isHidden = true
        }
        
        setPageLabel(pageNo: startIndex)
    }
    
    public func transitionShow() -> Void {
        transform = .identity
        layer.opacity = 1
    }
    
    public func transitionHide() -> Void {
        transform = .init(translationX: .zero, y: -frame.height)
        layer.opacity = 0
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
    
    private func setPageLabel(pageNo: Int) -> Void {
        countLabel.text = "\(pageNo)/\(imageCount)"
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

extension TopShadeView: PageDelegate {
    func didScrollTo(pageNo: Int) -> Void {
        setPageLabel(pageNo: pageNo)
    }
}

protocol CloseDelegate: AnyObject {
    @MainActor
    func closeGallery() -> Void
}

protocol ShadeToggleDelegate: AnyObject {
    @MainActor
    func toggleShades() -> Void
}