//
//  CardBackground.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 21/11/21.
//

import UIKit

final class CardBackground: UIButton {
    
    private let clipper = CornerClipView()
    private let triangleView: TriangleView
    
    /// How far the view will be inset from its superview.
    public static let Inset: CGFloat = 10
    public static let EdgeInsets: UIEdgeInsets = .init(top: CardBackground.Inset, left: CardBackground.Inset, bottom: CardBackground.Inset, right: CardBackground.Inset)
    private let triangleSize: CGFloat = 18
    
    @MainActor
    init() {
        self.triangleView = TriangleView(size: triangleSize)
        super.init(frame: .zero)
        
        /// Round corners.
        layer.cornerCurve = .continuous
        
        addSubview(clipper)
        
        /// Align view to top right, with fixed size.
        clipper.addSubview(triangleView)
        triangleView.constrain(to: clipper)
        
        /// Hide by default.
        triangleView.isHidden = true
        
        styleDefault()
    }
    
    public func constrain(toView view: UIView, insets: UIEdgeInsets, cornerRadius: CGFloat) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom),
            leftAnchor.constraint(equalTo: view.leftAnchor, constant: insets.left),
            rightAnchor.constraint(equalTo: view.rightAnchor, constant: -insets.right),
        ])
        layer.cornerRadius = cornerRadius
        clipper.constrain(to: self, cornerRadius: cornerRadius)
    }
    
    public func constrain(to guide: UILayoutGuide, insets: UIEdgeInsets, cornerRadius: CGFloat) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: guide.topAnchor, constant: insets.top),
            bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -insets.bottom),
            leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -insets.right),
        ])
        layer.cornerRadius = cornerRadius
        clipper.constrain(to: self, cornerRadius: cornerRadius)
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
