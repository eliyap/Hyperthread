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
    public let triangleView: TriangleView
    
    init(inset: CGFloat) {
        self.inset = inset
        let size = inset * 3
        self.triangleView = TriangleView(size: size)
        super.init(frame: .zero)
        
        /// Round corners.
        let radius = inset * 2
        layer.cornerRadius = radius
        layer.cornerCurve = .continuous
        
        let clipper = CornerClipView()
        addSubview(clipper)
        clipper.constrain(to: self, cornerRadius: radius)
        
        /// Align view to top right, with fixed size.
        clipper.addSubview(triangleView)
        triangleView.constrain(to: clipper)
        
        /// Hide by default.
        triangleView.isHidden = true
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
