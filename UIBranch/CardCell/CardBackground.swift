//
//  CardBackground.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 21/11/21.
//

import UIKit

final class CardBackground: UIButton {
    
    /// How far the view will be inset from its superview.
    private let inset: CGFloat
    
    init(inset: CGFloat) {
        self.inset = inset
        super.init(frame: .zero)
        
        /// Round corners.
        layer.cornerRadius = inset * 2
        layer.cornerCurve = .continuous
        
        /// Clip triangle to rounded corner.
        layer.masksToBounds = true
        
        let size = inset * 4
        let triangleView = TriangleView(size: size)
        addSubview(triangleView)
        triangleView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            triangleView.topAnchor.constraint(equalTo: topAnchor),
            triangleView.rightAnchor.constraint(equalTo: rightAnchor),
            triangleView.heightAnchor.constraint(equalToConstant: size),
            triangleView.widthAnchor.constraint(equalToConstant: size),
        ])
    }
    
    public func constrain(to guide: UILayoutGuide) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: guide.topAnchor, constant: inset),
            bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -inset),
            leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: inset),
            trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -inset),
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
