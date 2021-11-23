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
    
    private let imageView = IconImageView()
    private let label = UILabel()
    
    private let textStyle = UIFont.TextStyle.footnote
    private let symbolConfig: UIImage.SymbolConfiguration?
    
    init(sfSymbol: String, symbolConfig: UIImage.SymbolConfiguration? = nil) {
        self.symbolConfig = symbolConfig
        super.init(frame: .zero)
        
        /// Configure Main Stack View.
        axis = .horizontal
        alignment = .leading
        spacing = 4
        
        addArrangedSubview(imageView)
        addArrangedSubview(label)

        label.font = UIFont.preferredFont(forTextStyle: self.textStyle)
        
        setImage(to: sfSymbol)

        /// Mute Colors.
        label.textColor = .secondaryLabel
    }

    public func setText(to text: String) {
        label.text = text
    }
    
    public func setImage(to sfSymbol: String) {
        imageView.image = UIImage(systemName: sfSymbol)
        var config = UIImage.SymbolConfiguration.init(paletteColors: [.secondaryLabel])
        config = config.applying(UIImage.SymbolConfiguration(textStyle: self.textStyle))
        if let other = symbolConfig {
            config = config.applying(other)
        }
        imageView.preferredSymbolConfiguration = config
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class IconImageView: UIImageView {
    init() {
        super.init(frame: .zero)
        tintColor = .secondaryLabel
        contentMode = .scaleAspectFit
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
