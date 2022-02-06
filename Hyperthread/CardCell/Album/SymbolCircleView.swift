//
//  SymbolCircleView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 6/2/22.
//

import UIKit

final class SymbolCircleView: UIVisualEffectView {
    public let imageView: UIImageView = .init()
    
    @MainActor
    init() {
        super.init(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        contentView.addSubview(imageView)
    }
    
    func constrain(to view: UIView) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerYAnchor.constraint(equalTo: view.centerYAnchor),
            heightAnchor.constraint(equalTo: imageView.heightAnchor),
            
            /// Make view have aspect ratio 1.
            widthAnchor.constraint(equalTo: heightAnchor),
        ])
    }
    
    public enum Symbol {
        case hidden
        case GIF
        case video
        case offline
        case error
    }
    
    public func set(symbol: Symbol) -> Void {
        
        switch symbol {
        case .hidden:
            isHidden = true
        
        case .GIF:
            let config = UIImage.SymbolConfiguration(hierarchicalColor: .white)
                .applying(UIImage.SymbolConfiguration(textStyle: .largeTitle))
            isHidden = false
            imageView.image = UIImage(systemName: "gift.circle", withConfiguration: config)
        
        case .video:
            let config = UIImage.SymbolConfiguration(hierarchicalColor: .white)
                .applying(UIImage.SymbolConfiguration(textStyle: .largeTitle))
            isHidden = false
            imageView.image = UIImage(systemName: "play.circle", withConfiguration: config)
        
        case .offline:
            let config = UIImage.SymbolConfiguration(hierarchicalColor: .tertiaryLabel)
                .applying(UIImage.SymbolConfiguration(textStyle: .largeTitle))
            isHidden = false
            imageView.image = UIImage(systemName: "wifi.slash", withConfiguration: config)
        
        case .error:
            let config = UIImage.SymbolConfiguration(hierarchicalColor: .tertiaryLabel)
                .applying(UIImage.SymbolConfiguration(textStyle: .largeTitle))
            isHidden = false
            imageView.image = UIImage(systemName: "wifi.exclamationmark", withConfiguration: config)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("No.")
    }
}
