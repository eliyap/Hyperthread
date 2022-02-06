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
    
    private var playerLayer: LayerClass { layer as! LayerClass }
    
    private var playerLooper: AVPlayerLooper? = nil
    
    private let queuePlayer: AVQueuePlayer = .init()
    @MainActor
    public init() {
        super.init(frame: .zero)
        
        playerLayer.videoGravity = .resizeAspect
        playerLayer.player = queuePlayer
        
        constrain()
    }
    
    public func playLoopingGIF(from url: URL) -> Void {
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
