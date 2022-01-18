//
//  TableTopBar.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 18/1/22.
//

import Foundation
import UIKit

final class TableTopBar: UIVisualEffectView {
    
    private let stack: UIStackView = .init()
    private let label: UILabel = .init()
    private let loading: UIActivityIndicatorView = .init()
    private let icon: UIImageView = .init()
    
    init() {
        super.init(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        
        contentView.addSubview(stack)
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        
        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(loading)

        icon.image = UIImage(systemName: "arrow.down.circle.fill")
        icon.preferredSymbolConfiguration = .init(textStyle: .body)
            .applying(UIImage.SymbolConfiguration(paletteColors: [.label]))
        icon.contentMode = .scaleAspectFit
        
        label.text = "Loading..."
        loading.hidesWhenStopped = true
        loading.startAnimating()
    }
    
    public func constrain(to view: UIView) -> Void {
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            /// Safe area guarantees this sits below the navigation bar.
            self.safeAreaLayoutGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            /// Non-safe-area lets this extend into the notch / home indicator area.
            self.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: CardTeaserCell.borderInset),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -CardTeaserCell.borderInset),
            /// Keep stack contents away from notch / home indicator in iPhone X portrait mode.
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: CardTeaserCell.borderInset),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -CardTeaserCell.borderInset),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
