//
//  ColorMarkerView.swift
//  
//
//  Created by Secret Asian Man Dev on 3/1/22.
//

import Foundation
import UIKit

final class ColorMarkerView: UIStackView {
    
    private let symbolButton = UIButton()
    private let bottomLine = UIButton()
    
    private let colorMarkerWidth: CGFloat = 1.5
    
    init() {
        super.init(frame: .zero)
        axis = .vertical
        alignment = .center
        
        addArrangedSubview(symbolButton)
        addArrangedSubview(bottomLine)
        
        /// Configure Symbol.
        var config = UIImage.SymbolConfiguration.init(paletteColors: [.secondaryLabel])
        config = config.applying(UIImage.SymbolConfiguration(textStyle: .footnote))
        symbolButton.setPreferredSymbolConfiguration(config, forImageIn: .normal)
        symbolButton.setImage(UIImage(systemName: "circle"), for: .normal)
    }
    
    public func constrain(to view: UIView) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topAnchor.constraint(equalTo: view.topAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor),
            heightAnchor.constraint(equalTo: view.heightAnchor),
        ])
        
        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        
        /// Shape the button as a vertical capsule shape.
        bottomLine.layer.cornerRadius = colorMarkerWidth / 2
        NSLayoutConstraint.activate([
            bottomLine.widthAnchor.constraint(equalToConstant: colorMarkerWidth),
        ])
        
        /// Request line be "as tall as possible".
        let superTall = bottomLine.heightAnchor.constraint(equalToConstant: .superTall)
        superTall.priority = .defaultLow
        superTall.isActive = true
        
        symbolButton.translatesAutoresizingMaskIntoConstraints = false
    }
    
    public func configure(node: Node) -> Void {
        bottomLine.backgroundColor = SCColors[(node.depth - 1) % SCColors.count]
        
        switch node.tweet.primaryReferenceType {
        
        case .replied_to:
            symbolButton.isHidden = false
            symbolButton.setImage(UIImage(systemName: ReplySymbol.name), for: .normal)
        
        case .quoted:
            symbolButton.isHidden = false
            symbolButton.setImage(UIImage(systemName: QuoteSymbol.name), for: .normal)
        
        default:
            symbolButton.isHidden = true

            /// Placeholder image prevents height shrinking to zero, which leads to graphical glitches.
            symbolButton.setImage(UIImage(systemName: "circle"), for: .normal)
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
