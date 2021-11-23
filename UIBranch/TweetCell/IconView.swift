//
//  IconView.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 13/11/21.
//

import UIKit
import RealmSwift
import Twig

final class IconView: UIStackView {
    
    public let imageView: IconImageView
    private let label = UILabel()
    
    public static let textStyle = UIFont.TextStyle.footnote
    
    init(sfSymbol: String, symbolConfig: UIImage.SymbolConfiguration? = nil) {
        imageView = IconImageView(sfSymbol: sfSymbol, symbolConfig: symbolConfig)
        super.init(frame: .zero)
        
        /// Configure Main Stack View.
        axis = .horizontal
        alignment = .leading
        spacing = 4
        
        addArrangedSubview(imageView)
        addArrangedSubview(label)

        label.font = UIFont.preferredFont(forTextStyle: Self.textStyle)
        
        /// Mute Colors.
        label.textColor = .secondaryLabel
    }

    public func setText(to text: String) {
        label.text = text
    }
    
    

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class IconImageView: UIImageView {
    
    public private(set) var sfSymbol: String
    
    public init(sfSymbol: String, symbolConfig: UIImage.SymbolConfiguration? = nil) {
        self.sfSymbol = sfSymbol
        super.init(frame: .zero)
        tintColor = .secondaryLabel
        contentMode = .scaleAspectFit
        
        /// Applying a text style causes image to scale with Dynamic Type.
        var config = UIImage.SymbolConfiguration.init(paletteColors: [.secondaryLabel])
        config = config.applying(UIImage.SymbolConfiguration(textStyle: IconView.textStyle))
        
        /// Combine with other configuration.
        if let other = symbolConfig {
            config = config.applying(other)
        }
        
        preferredSymbolConfiguration = config
        
        image = UIImage(systemName: sfSymbol)
    }
    
    public func setImage(to sfSymbol: String) {
        image = UIImage(systemName: sfSymbol)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
