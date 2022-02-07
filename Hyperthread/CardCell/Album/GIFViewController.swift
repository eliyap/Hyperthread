//
//  GIFViewController.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 6/2/22.
//  Based on reference implementation at: https://developer.apple.com/documentation/avfoundation/avplayerlayer

import UIKit
import AVFoundation
import BlackBox

final class GIFView: UIView {
    
    public typealias LayerClass = AVPlayerLayer
    
    /// Override the property to make AVPlayerLayer the view's backing layer.
    override static var layerClass: AnyClass { LayerClass.self }
    
    private var playerLayer: LayerClass { layer as! LayerClass }
    private var playerLooper: AVPlayerLooper? = nil
    private let queuePlayer: AVQueuePlayer = .init()
    
    private let progressBar: GIFProgressBarView = .init()
    
    @MainActor
    public init() {
        super.init(frame: .zero)
        
        playerLayer.videoGravity = .resizeAspect
        playerLayer.player = queuePlayer
        
        constrain()

        addSubview(progressBar)
        progressBar.constrain(to: self)
        
        queuePlayer.addPeriodicTimeObserver(forInterval: GIFProgressBarView.UpdateInterval, queue: .main, using: { [weak self] (time: CMTime) in
            /// Normal for `self` to become `nil` when scrolling.
            guard let self = self else { return }
            
            guard let item = self.queuePlayer.currentItem else {
                Logger.general.error("Could not obtain player item!")
                assert(false)
                return
            }
            
            let proportion = time.seconds / item.duration.seconds
            self.progressBar.setProportion(to: proportion)
        })
    }
    
    public func playLoopingGIF(from url: URL) -> Void {
        /// Example code from https://developer.apple.com/documentation/avfoundation/avplayerlooper
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        self.playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        queuePlayer.play()
    }
    
    public func constrain() -> Void {
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

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
    let solid = UIImageView.solidTemplate
    
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

/// Templated, resizable, solid image intended to fill a `UIVisualEffectView`.
/// This causes the vibrancy effect to fill the whole view.
///
/// > `UIImageView` objects with images that have a rendering mode of `UIImage.RenderingMode.alwaysTemplate`
/// > as well as `UILabel` objects will update automatically.
///
/// Source: https://developer.apple.com/documentation/uikit/uivibrancyeffect
fileprivate extension UIImageView {
    static let solidTemplate: UIImageView = {
        let view = UIImageView()
        guard let image = UIImage(color: UIColor.black)?.withRenderingMode(.alwaysTemplate) else {
            Logger.general.error("Failed to render template image!")
            assert(false)
            return view
        }
        view.image = image
        view.contentMode = .scaleToFill
        return view
    }()
}

fileprivate extension UIImage {
    /// Creates an image filled with solid color.
    /// Source: https://stackoverflow.com/questions/26542035/create-uiimage-with-solid-color-in-swift
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}
