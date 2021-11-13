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
    
    private let imageView = UIImageView()
    private let label = UILabel()
    
    init(sfSymbol: String, config: UIImage.SymbolConfiguration? = nil) {
        super.init(frame: .zero)
        
        /// Configure Main Stack View.
        axis = .horizontal
        alignment = .leading
        spacing = 4
        imageView.contentMode = .scaleAspectFit
        
        addArrangedSubview(imageView)
        addArrangedSubview(label)

        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        
        imageView.image = UIImage(systemName: sfSymbol)
        if let config = config {
            imageView.preferredSymbolConfiguration = config
        }

        // Mute Colors.
        imageView.tintColor = .secondaryLabel
        label.textColor = .secondaryLabel
    }

    public func setText(to text: String) {
        label.text = text
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
