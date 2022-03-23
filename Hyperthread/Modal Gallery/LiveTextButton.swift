//
//  LiveTextButton.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 23/3/22.
//

import UIKit
import BlackBox

final class LiveTextButton: UIButton {
    
    private let textIcon: UIImageView
    
    /// Displays the loading progress of the live text vision request.
    private let loadView: LoadCircleView
    
    private var progress: Double = 0
    
    public weak var textRequestDelegate: TextRequestDelegate? = nil
    
    @MainActor
    init() {
        self.textIcon = .init(image: Self.icon(state: .loading))
        self.loadView = .init()
        super.init(frame: .zero)
        
        addSubview(loadView)
        
        /// Prevents view from eating touches.
        loadView.isUserInteractionEnabled = false
        
        addSubview(textIcon)
        addAction(UIAction(handler: { [weak self] action in
            self?.textRequestDelegate?.didRequestText()
        }), for: .touchUpInside)
    }
    
    public func constrain(parent: UIView, sibling: UIView, horizontalMargin: CGFloat) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        textIcon.translatesAutoresizingMaskIntoConstraints = false
        
        /// Constrain visible part to superview, not actual area.
        NSLayoutConstraint.activate([
            parent.rightAnchor.constraint(equalToSystemSpacingAfter: textIcon.rightAnchor, multiplier: horizontalMargin),
            /// Ensure view covers label.
            textIcon.bottomAnchor.constraint(equalTo: sibling.bottomAnchor),
            textIcon.topAnchor.constraint(equalTo: sibling.topAnchor),
        ])
        
        /// Expand hitbox in all directions to provide a generous touch target.
        /// Because this button is in a hard to hit position, it's extra important to be generous.
        NSLayoutConstraint.activate([
            textIcon.leftAnchor.constraint(equalToSystemSpacingAfter: leftAnchor, multiplier: 2),
            rightAnchor.constraint(equalToSystemSpacingAfter: textIcon.rightAnchor, multiplier: 2),
            textIcon.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 2),
            bottomAnchor.constraint(equalToSystemSpacingBelow: textIcon.bottomAnchor, multiplier: 2),
        ])
        
        loadView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadView.centerXAnchor.constraint(equalTo: textIcon.centerXAnchor),
            loadView.centerYAnchor.constraint(equalTo: textIcon.centerYAnchor),
            
            /// Diameter of circle should match or exceed diagonal of (squarish) image.
            loadView.heightAnchor.constraint(equalTo: textIcon.heightAnchor, multiplier: sqrt(2.0)),
            loadView.widthAnchor.constraint(equalTo: textIcon.heightAnchor, multiplier: sqrt(2.0)),
        ])
    }
    
    private static func icon(state: VisionRequestState) -> UIImage? {
        return UIImage(systemName: "text.viewfinder", withConfiguration: state.symbolConfig)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LiveTextButton: ImageVisionDelegate {
    func didReport(progress: Double) {
        self.progress = progress
        
        /// Disable presses until signalled complete.
        isEnabled = (progress == 1)
        
        if progress == 1 {
            textIcon.image = Self.icon(state: .ready)
        } else {
            textIcon.image = Self.icon(state: .loading)
        }
        
        loadView.didReport(progress: progress)
    }
    
    func didChangeHighlightState(to highlighting: Bool) {
        if highlighting {
            textIcon.image = Self.icon(state: .highlighting)
        } else {
            textIcon.image = Self.icon(state: .ready)
        }
        loadView.didChangeHighlightState(to: highlighting)
    }
}

final class LoadCircleView: UIView {
    
    /// Ranges from 0 to 1.
    private var reportedProgress: Double = 0.0
    
    private let shapeLayer: CAShapeLayer
    
    /// Make indicator low contrast, so it's subtle.
    /// This is non-interactive, and non-actionable, so it is fine if this is never seen.
    /// Color approximates `UIColor.sytemGray5` in dark mode.
    public static let loadingColor: CGColor = UIColor(white: 0.2125, alpha: 1).cgColor
    
    @MainActor
    init() {
        self.shapeLayer = .init()
        super.init(frame: .zero)
        
        layer.addSublayer(shapeLayer)
        
        shapeLayer.fillColor = Self.loadingColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        /// Use saved progress.
        redraw(progress: self.reportedProgress)
    }
    
    private func redraw(progress: Double) -> Void {
        /// Save some time for zero progress.
        guard progress > 0 else {
            shapeLayer.path = nil
            return
        }
        
        /// We assume the view is a square, but take the shorter side just in case.
        let sideLength = min(frame.height, frame.width)
        
        let path = UIBezierPath()
        
        let deadCenter = CGPoint(x: sideLength / 2, y: sideLength / 2)
        path.move(to: deadCenter)
        
        /// Start at 12 o clock.
        let topMid = CGPoint(x: sideLength / 2, y: 0)
        path.addLine(to: topMid)
        
        path.addArc(
            withCenter: deadCenter,
            radius: sideLength / 2,
            /// Start at 12 o clock.
            startAngle: -.pi / 2,
            /// Subtract 90 deg to rotate from +x axis.
            endAngle: (progress * 2 * .pi) - .pi / 2,
            clockwise: true
        )
        
        path.close()
        shapeLayer.path = path.cgPath
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension LoadCircleView: ImageVisionDelegate {
    func didReport(progress: Double) -> Void {
        print("drawing progress \(progress)")
        self.reportedProgress = progress
        redraw(progress: progress)
    }
    
    func didChangeHighlightState(to highlighting: Bool) {
        if highlighting {
            shapeLayer.fillColor = UIColor.white.cgColor
        } else {
            shapeLayer.fillColor = Self.loadingColor
        }
        
        /// Safety check.
        if highlighting {
            guard reportedProgress == 1 else {
                assert(false, "Tried to draw without finishing progress!")
                BlackBox.Logger.general.warning("Tried to draw without finishing progress!")
                return
            }
        }
    }
}

enum VisionRequestState {
    case loading, ready, highlighting
    
    private static let baseConfig = UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .body))
    var symbolConfig: UIImage.SymbolConfiguration {
        Self.baseConfig.applying(UIImage.SymbolConfiguration(paletteColors: [self.symbolColor]))
    }
    
    var symbolColor: UIColor {
        switch self {
        case .loading:
            /// Mode independent color.
            /// Approximates `UIColor.systemGray2` in dark mode.
            return UIColor(white: 0.4785, alpha: 1)
        case .ready:
            return .galleryUI
        case .highlighting:
            return .galleryBackground
        }
    }
}
