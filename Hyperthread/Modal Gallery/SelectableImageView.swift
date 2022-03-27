//
//  SelectableImageView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 26/3/22.
//

import UIKit
import Vision
import BlackBox

final class SelectableImageView: UIView {
    
    private let visionImageView: VisionImageView
    
    /// Passthroughs.
    var image: UIImage? {
        get { visionImageView.image }
        set { visionImageView.image = newValue }
    }
    
    /// Delegates.
    public weak var imageVisionDelegate: ImageVisionDelegate? {
        get { visionImageView.imageVisionDelegate }
        set { visionImageView.imageVisionDelegate = newValue }
    }
    
    public weak var textRequestDelegate: TextRequestDelegate? {
        visionImageView
    }
    
    @MainActor
    init() {
        self.visionImageView = .init()
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
