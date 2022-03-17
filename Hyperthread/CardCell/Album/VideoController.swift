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
    /**
     * This class formalizes a retry policy for loading Twitter videos.
     * 
     * As of 22.03.16, we observed a rare (~1/100 requests) error 
     * (Code=-11850 "Operation Stopped") when loading a video from Twitter.
     * 
     * Retrying seems to fix the issue.
     */
    
    private let videoPlayer: AVPlayer = .init()
    
    /// Retains observation on playing video item.
    private var videoObservation: NSKeyValueObservation? = nil

    public static let retryDelay: TimeInterval = 0.5

    public static let maxRetries = 10
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.player = videoPlayer
    }
    
    public func play(url: URL, retryNumber: Int = 0) -> Void {
        /// Observe item, not player, as suggested in docs.
        /// Docs: https://developer.apple.com/documentation/avfoundation/avplayer/1388096-status
        let vidItem: AVPlayerItem = .init(url: url)
        self.videoObservation = vidItem.observe(
            \.status,
             changeHandler: { [weak self] (object, change) in
                 self?.respond(to: object, url: url, retryNumber: retryNumber)
             })
        
        videoPlayer.replaceCurrentItem(with: vidItem)
    }
    
    private func respond(to updatedItem: AVPlayerItem, url: URL, retryNumber: Int) -> Void {
        if updatedItem.status == .failed {
            TableLog.error("""
               Failed to play video!
               - URL: \(url)
               - Error: \(String(describing: updatedItem.error))
               """)
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.retryDelay, execute: { [weak self] in
                guard retryNumber < Self.maxRetries else {
                    TableLog.error("Failed to play video after \(Self.maxRetries) retries!")
                    return
                }
                self?.play(url: url, retryNumber: retryNumber + 1)
            })
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
