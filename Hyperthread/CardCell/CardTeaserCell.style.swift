//
//  CardTeaserCell.style.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 12/2/22.
//

import UIKit

extension CardTeaserCell {
    public func style(selected: Bool) -> Void {
        UIView.animate(withDuration: 0.25) { [weak self] in
            guard let self = self else {
                assert(false, "self is nil")
                return
            }
            /// By changing the radius, offset, and transform at the same time, we can grow / shrink the shadow in place,
            /// creating a "lifting" illusion.
            if selected {
                self.styleSelected()
            } else {
                self.resetStyle()
            }
        }
    }
    
    public func styleSelected() -> Void {
        /// Try to avoid clipping the shadow by keeping `shadow < inset`.
        let shadowSize = CardTeaserCell.ContentInset * 0.75
        
        stackView.transform = CGAffineTransform(translationX: 0, y: -shadowSize)
        cardBackground.transform = CGAffineTransform(translationX: 0, y: -shadowSize)
        cardBackground.layer.shadowColor = UIColor.black.cgColor
        cardBackground.layer.shadowOpacity = 0.3
        cardBackground.layer.shadowRadius = shadowSize
        cardBackground.layer.shadowOffset = CGSize(width: .zero, height: shadowSize)
        
        cardBackground.styleSelected()
    }
    
    public func resetStyle() -> Void {
        stackView.transform = CGAffineTransform(translationX: 0, y: 0)
        cardBackground.transform = CGAffineTransform(translationX: 0, y: 0)
        cardBackground.layer.shadowColor = UIColor.black.cgColor
        cardBackground.layer.shadowOpacity = 0
        cardBackground.layer.shadowRadius = 0
        cardBackground.layer.shadowOffset = CGSize.zero
        
        cardBackground.styleDefault()
    }
}
