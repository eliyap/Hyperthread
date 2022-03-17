//
//  VideoController.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 16/3/22.
//

import Foundation
import UIKit
import AVKit

final class VideoController: AVPlayerViewController {
    
    private let videoPlayer: AVPlayer = .init()
    
    /// Retains observation on playing video item.
    private var videoObservation: NSKeyValueObservation? = nil
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.player = videoPlayer
    }
    
    public func play(url: URL) -> Void {
        /// Observe item, not player, as suggested in docs.
        /// Docs: https://developer.apple.com/documentation/avfoundation/avplayer/1388096-status
        let vidItem: AVPlayerItem = .init(url: url)
        self.videoObservation = vidItem.observe(
            \.status,
             changeHandler: { [weak self] (object, change) in
                 self?.respond(to: object, url: url)
             })
        
        videoPlayer.replaceCurrentItem(with: vidItem)
    }
    
    private func respond(to updatedItem: AVPlayerItem, url: URL) -> Void {
        if updatedItem.status == .failed {
            TableLog.error("""
               Failed to play video!
               - URL: \(url)
               - Error: \(String(describing: updatedItem.error))
               """)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [weak self] in
                self?.play(url: url)
            })
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
