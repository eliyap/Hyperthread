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
    
    init(pageView: ModalPageView) {
        self.pageView = pageView
        self.topShade = .init()
        super.init(frame: .zero)
        
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

extension GalleryView: GeometryTargetProvider {
    var targetView: UIView {
        pageView.targetView
    }
}

final class TopShadeView: UIStackView {
    
    private let countLabel: UILabel
    
    /// Translucent gradient background to keep label legible even against white images.
    /// Shamelessly copied from Apollo.
    private let gradientLayer: CAGradientLayer
    
    @MainActor
    init() {
        self.countLabel = .init()
        self.gradientLayer = .init()
        super.init(frame: .zero)
        
        addSubview(countLabel)
        
        /// Gradient should be behind all other layers.
        layer.insertSublayer(gradientLayer, at: 0)
        gradientLayer.colors = [
            UIColor.galleryBackground.withAlphaComponent(0.7).cgColor,
            UIColor.clear.cgColor
        ]
        
        countLabel.text = "–/–"
        countLabel.textColor = .white /// To contrast with black.
    }
    
    override func layoutSubviews() {
        gradientLayer.frame = frame
        super.layoutSubviews()
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
        
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            countLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            /// Ensure view covers label.
            countLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            bottomAnchor.constraint(equalToSystemSpacingBelow: countLabel.bottomAnchor, multiplier: 1),
        ])
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
