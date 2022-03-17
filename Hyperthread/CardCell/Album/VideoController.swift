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
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
