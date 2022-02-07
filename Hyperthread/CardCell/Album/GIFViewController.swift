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
        queuePlayer.isMuted = true
        queuePlayer.play()
    }
    
    public func constrain() -> Void {
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
