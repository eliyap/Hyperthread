//
//  BottomShadeView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 20/3/22.
//

import UIKit

final class BottomShadeView: UIView {
    
    private let stack: UIStackView
    
    private let shareButton: UIButton
    
    private let config = UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .body))
        .applying(UIImage.SymbolConfiguration(paletteColors: [.galleryUI]))
    
    @MainActor
    init() {
        self.shareButton = .init()
        self.stack = .init(arrangedSubviews: [
            shareButton,
        ])
        super.init(frame: .zero)
        backgroundColor = .galleryShade
        
        addSubview(stack)
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        
        shareButton.setImage(UIImage(systemName: "square.and.arrow.up", withConfiguration: config), for: .normal)
    }
    
    public func constrain(to view: UIView) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            /// Pin own bottom ignoring safe area.
            bottomAnchor.constraint(equalTo: view.bottomAnchor),
            /// But ensure stack is clear of safe area.
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            /// Similarly, pin sides to screen edges, but stack to safe margins.
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            /// Finally, give this view height by using the stack view's intrinsic height.
            stack.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 1)
        ])
    }
    
    public func transitionShow() -> Void {
        transform = .identity
        layer.opacity = 1
    }
    
    public func transitionHide() -> Void {
        transform = .init(translationX: .zero, y: frame.height)
        layer.opacity = 0
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
