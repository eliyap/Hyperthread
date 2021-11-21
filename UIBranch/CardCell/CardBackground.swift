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
    private let triangleView: TriangleView
    
    init(inset: CGFloat) {
        self.inset = inset
        let size = inset * 4
        self.triangleView = TriangleView(size: size)
        super.init(frame: .zero)
        
        /// Round corners.
        layer.cornerRadius = inset * 2
        layer.cornerCurve = .continuous
        
        /// Clip triangle to rounded corner.
        layer.masksToBounds = true
        
        addSubview(triangleView)
        
        /// Align view to top right, with fixed size.
        triangleView.constrain(to: safeAreaLayoutGuide)
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

final class TriangleView: UIView {
    
    private let triangleLayer: TriangleLayer
    private let size: CGFloat
    
    init(size: CGFloat) {
        self.size = size
        triangleLayer = TriangleLayer(size: size)
        super.init(frame: CGRect(origin: .zero, size: CGSize(width: size, height: size)))
        
        layer.addSublayer(triangleLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func constrain(to guide: UILayoutGuide) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: guide.topAnchor),
            rightAnchor.constraint(equalTo: guide.rightAnchor),
            heightAnchor.constraint(equalToConstant: size),
            widthAnchor.constraint(equalToConstant: size),
        ])
    }
}

final class TriangleLayer: CAShapeLayer {
    
    let size: CGFloat
    
    init(size: CGFloat) {
        self.size = size
        super.init()
        let path = UIBezierPath()
        
        /// Draw Triangle.
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: size, y: .zero))
        path.addLine(to: CGPoint(x: size, y: size))
        path.close()
        
        self.path = path.cgPath
        
        fillColor = UIColor.systemRed.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
