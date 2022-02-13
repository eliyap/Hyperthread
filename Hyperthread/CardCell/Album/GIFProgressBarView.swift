//
//  GIFProgressBarView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 7/2/22.
//

import UIKit
import AVFoundation
import BlackBox

final class GIFProgressBarView: UIView {

    public static let UpdateInterval: CMTime = .init(value: 1, timescale: 60) /// - Note: arbitrary number. total guess.
    
    private let background: ProgressEffectView = .init()
    
    @MainActor
    public init() {
        super.init(frame: .zero)
        
        addSubview(background)
    }
    
    public static let Height: CGFloat = 5
    public func constrain(to view: UIView) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bottomAnchor.constraint(equalTo: view.bottomAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heightAnchor.constraint(equalToConstant: Self.Height),
        ])
        
        background.constrain(to: self)
    }
    
    @MainActor
    public func setProportion(to proportion: Double) -> Void {
        background.setProportion(to: proportion)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ProgressEffectView: UIVisualEffectView {
    
    public static let Effect = UIBlurEffect(style: .systemMaterial)
    
    private let bar: ProgressVibrancyView = .init()
    
    @MainActor
    public init() {
        super.init(effect: ProgressEffectView.Effect)
        contentView.addSubview(bar)
    }
    
    public func constrain(to view: UIView) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        bar.frame = self.bounds
        bar.constrain(to: self)
    }
    
    @MainActor
    public func setProportion(to proportion: Double) -> Void {
        let replacement = bar.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: proportion)
        replace(object: bar, on: \ProgressVibrancyView.widthConstraint, with: replacement)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ProgressVibrancyView: UIVisualEffectView {
    
    let label = UILabel()
    
    /// Solid template image subview in which the vibrancy effect is shown.
    /// Templated, resizable, solid image intended to fill a `UIVisualEffectView`.
    /// This causes the vibrancy effect to fill the whole view.
    ///
    /// > `UIImageView` objects with images that have a rendering mode of `UIImage.RenderingMode.alwaysTemplate`
    /// > as well as `UILabel` objects will update automatically.
    ///
    /// Source: https://developer.apple.com/documentation/uikit/uivibrancyeffect
    let solid = UIImageView.makeSolidTemplate(color: .black)
    
    public var widthConstraint: NSLayoutConstraint? = nil
    
    @MainActor
    public init() {
        super.init(effect: UIVibrancyEffect(blurEffect: ProgressEffectView.Effect))
        self.widthConstraint = widthAnchor.constraint(equalToConstant: .zero)
        contentView.addSubview(solid)
    }
    
    public func constrain(to view: UIView) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: view.topAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor),
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
        ])
        
        solid.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: solid.topAnchor),
            bottomAnchor.constraint(equalTo: solid.bottomAnchor),
            leadingAnchor.constraint(equalTo: solid.leadingAnchor),
            trailingAnchor.constraint(equalTo: solid.trailingAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
