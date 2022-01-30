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
    private let coloredLine = UIButton()
    
    private let colorMarkerWidth: CGFloat = 1.5
    
    @MainActor
    init() {
        super.init(frame: .zero)
        axis = .vertical
        alignment = .center
        
        addArrangedSubview(symbolButton)
        addArrangedSubview(coloredLine)
        
        /// Configure Symbol.
        var config = UIImage.SymbolConfiguration.init(paletteColors: [.secondaryLabel])
        config = config.applying(UIImage.SymbolConfiguration(textStyle: .caption2))
        symbolButton.setPreferredSymbolConfiguration(config, forImageIn: .normal)
        symbolButton.setImage(UIImage(systemName: "circle"), for: .normal)
    }
    
    public func constrain() -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        coloredLine.translatesAutoresizingMaskIntoConstraints = false
        
        /// Shape the button as a vertical capsule shape.
        coloredLine.layer.cornerRadius = colorMarkerWidth / 2
        NSLayoutConstraint.activate([
            coloredLine.widthAnchor.constraint(equalToConstant: colorMarkerWidth),
        ])
        
        /// Request line be "as tall as possible".
        let superTall = coloredLine.heightAnchor.constraint(equalToConstant: .superTall)
        superTall.priority = .defaultLow
        superTall.isActive = true
        
        symbolButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            /// Bind width to symbol, prevents view from growing too wide.
            widthAnchor.constraint(equalTo: symbolButton.widthAnchor),
            /// Enforce aspect ratio 1.
            symbolButton.widthAnchor.constraint(equalTo: symbolButton.heightAnchor),
        ])
    }
    
    public func configure(node: Node) -> Void {
        coloredLine.backgroundColor = SCColors[(node.depth - 1) % SCColors.count]
        
        switch node.tweet.primaryReferenceType {
        
        case .replied_to:
            symbolButton.isHidden = false
            symbolButton.setImage(UIImage(systemName: ReplySymbol.hollowName), for: .normal)
        
        case .quoted:
            symbolButton.isHidden = false
            symbolButton.setImage(UIImage(systemName: QuoteSymbol.hollowName), for: .normal)
            
        case .none:
            symbolButton.isHidden = false
            symbolButton.setImage(UIImage(systemName: "xmark.circle"), for: .normal)
        
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
