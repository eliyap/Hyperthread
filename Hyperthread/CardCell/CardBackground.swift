//
//  CardBackground.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 21/11/21.
//

import UIKit

final class CardBackground: UIButton {
    
    public let triangleView: TriangleView
    
    /// How far the view will be inset from its superview.
    public static let inset = CardTeaserCell.borderInset
    public class var cornerRadius: CGFloat { Self.inset * 2 }
    
    init() {
        self.triangleView = TriangleView(size: Self.inset * 3)
        super.init(frame: .zero)
        
        /// Round corners.
        layer.cornerRadius = Self.cornerRadius
        layer.cornerCurve = .continuous
        
        let clipper = CornerClipView()
        addSubview(clipper)
        clipper.constrain(to: self, cornerRadius: Self.cornerRadius)
        
        /// Align view to top right, with fixed size.
        clipper.addSubview(triangleView)
        triangleView.constrain(to: clipper)
        
        /// Hide by default.
        triangleView.isHidden = true
        
        styleDefault()
    }
    
    public func constrain(to guide: UILayoutGuide) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: guide.topAnchor, constant: Self.inset),
            bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -Self.inset),
            leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: Self.inset),
            trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -Self.inset),
        ])
    }
    
    public func configure(status: ReadStatus) {
        switch status {
        case .new:
            triangleView.triangleLayer.fillColor = UIColor.SCRed.cgColor
            triangleView.isHidden = false
        case .updated:
            triangleView.triangleLayer.fillColor = UIColor.SCYellow.cgColor
            triangleView.isHidden = false
        case .read:
            triangleView.isHidden = true
        }
    }
    
    public func styleSelected() -> Void {
        backgroundColor = .cardSelected
        layer.borderWidth = 0
        layer.borderColor = UIColor.secondarySystemFill.cgColor
    }
    
    public func styleDefault() -> Void {
        backgroundColor = .card
        layer.borderWidth = 1.00
        layer.borderColor = UIColor.secondarySystemFill.cgColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
