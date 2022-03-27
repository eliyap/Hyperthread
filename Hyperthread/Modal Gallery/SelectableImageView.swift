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
        
        addSubview(visionImageView)
        visionImageView.contentMode = .scaleAspectFit
        visionImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            visionImageView.topAnchor.constraint(equalTo: topAnchor),
            visionImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            visionImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            visionImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SelectableImageView: TextRequestDelegate {
    func didRequestText(show: Bool?) {
        visionImageView.didRequestText(show: show)
    }
}

extension SelectableImageView: ActiveCellDelegate {
    func didBecomeActiveCell() {
        visionImageView.didBecomeActiveCell()
    }
}
