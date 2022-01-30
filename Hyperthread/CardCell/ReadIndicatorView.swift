//
//  ReadIndicatorView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 21/11/21.
//

import UIKit

/// Clips subviews so that superview doesn't have to.
/// Specifically, clips `TriangleCorner` so that the card can have an out-of-bounds shadow,
/// which requires `masksToBounds = false`.
final class CornerClipView: UIView {
    
    @MainActor
    init() {
        super.init(frame: .zero)
        layer.masksToBounds = true
    }
    
    func constrain(to view: UIView, cornerRadius: CGFloat) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        layer.cornerRadius = cornerRadius
        layer.cornerCurve = .continuous
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class TriangleView: UIView {
    
    public let triangleLayer: TriangleLayer
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
    
    public func constrain(to view: UIView) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor),
            rightAnchor.constraint(equalTo: view.rightAnchor),
            heightAnchor.constraint(equalToConstant: size),
            widthAnchor.constraint(equalToConstant: size),
        ])
    }
}

final class TriangleLayer: CAShapeLayer {
    
    let size: CGFloat
    
    /// A copy initializer which is implicitly invoked, sometimes.
    /// https://stackoverflow.com/questions/31892986/why-does-cabasicanimation-try-to-initialize-another-instance-of-my-custom-calaye/36017699
    override init(layer: Any) {
        if let layer = layer as? Self {
            self.size = layer.size
        } else {
            assert(false, "Init with wrong type!")
            self.size = .zero
        }
        super.init()
        drawTriangle()
    }
    
    init(size: CGFloat) {
        self.size = size
        super.init()
        drawTriangle()
    }
    
    fileprivate func drawTriangle() {
        let path = UIBezierPath()
        
        /// Draw Triangle.
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: size, y: .zero))
        path.addLine(to: CGPoint(x: size, y: size))
        path.close()
        
        self.path = path.cgPath
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
