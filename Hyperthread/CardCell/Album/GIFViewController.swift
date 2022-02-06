//
//  GIFViewController.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 6/2/22.
//  Based on reference implementation at: https://developer.apple.com/documentation/avfoundation/avplayerlayer

import UIKit
import AVFoundation

final class GIFView: UIView {
    
    public typealias LayerClass = AVPlayerLayer
    
    /// Override the property to make AVPlayerLayer the view's backing layer.
    override static var layerClass: AnyClass { LayerClass.self }
    
    /// The associated player object.
    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
    
    private var playerLayer: LayerClass { layer as! LayerClass }
    
    @MainActor
    public init() {
        super.init(frame: .zero)
        playerLayer.videoGravity = .resizeAspect
        
        constrain()
    }
    
    public func constrain() -> Void {
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
