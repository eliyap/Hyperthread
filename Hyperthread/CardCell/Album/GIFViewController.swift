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
    
    /// Retains observation on playing video item.
    private var itemObservation: NSKeyValueObservation? = nil
    
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
            
            /// Normal for this to be `nil` when scrolling.
            guard let item = self.queuePlayer.currentItem else {
                Logger.general.error("Could not obtain player item!")
                return
            }
            
            let proportion = time.seconds / item.duration.seconds
            self.progressBar.setProportion(to: proportion)
        })
        
        /// When app returns to the foreground, GIFs shoul be unpaused.
        NotificationCenter.default.addObserver(self, selector: #selector(resumePlayback), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    public func playLoopingGIF(from url: URL) -> Void {
        /// Example code from https://developer.apple.com/documentation/avfoundation/avplayerlooper
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        self.playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        
        self.itemObservation = playerItem.observe(
            \.status,
             changeHandler: { (object, change) in
                 #warning("Incomplete bug investigation into crashing GIFs!")
//                 print("ready: \(object.status == .readyToPlay)")
             }
        )
        
        queuePlayer.isMuted = true
        queuePlayer.play()
    }
    
    @objc
    private func resumePlayback(_: NSNotification) -> Void {
        guard isHidden == false else { return }
        queuePlayer.play()
    }
    
    public func constrain() -> Void {
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
