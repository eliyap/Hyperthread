//
//  TableTopBar.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 18/1/22.
//

import Foundation
import UIKit
import Combine

final class TableTopBar: UIVisualEffectView {
    
    private let stackView: UIStackView = .init()
    private let label: UILabel = .init()
    private let loadingView: UIActivityIndicatorView = .init()
    private let iconView: UIImageView = .init()
    
    private var observers: Set<AnyCancellable> = []
    
    init(loadingConduit: PassthroughSubject<Bool, Never>) {
        super.init(effect: UIBlurEffect(style: .systemUltraThinMaterial))
        
        contentView.addSubview(stackView)
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        
        stackView.addArrangedSubview(iconView)
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(loadingView)

        iconView.preferredSymbolConfiguration = .init(textStyle: .body)
            .applying(UIImage.SymbolConfiguration(paletteColors: [.label]))
        iconView.contentMode = .scaleAspectFit
        
        loadingView.hidesWhenStopped = true
        
        loadingConduit
            .sink { [weak self] in self?.setState(isLoading: $0) }
            .store(in: &observers)
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
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: CardTeaserCell.borderInset),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -CardTeaserCell.borderInset),
            /// Keep stack contents away from notch / home indicator in iPhone X portrait mode.
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: CardTeaserCell.borderInset),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -CardTeaserCell.borderInset),
        ])
    }
    
    public func setState(isLoading: Bool) -> Void {
        /// UI code **must** run on the main thread!
        DispatchQueue.main.async { [weak self] in
            if isLoading {
                self?.iconView.image = UIImage(systemName: "arrow.down.circle.fill")
                self?.label.text = "Loading..."
                self?.loadingView.startAnimating()
            } else {
                self?.iconView.image = UIImage(systemName: "checkmark.circle.fill")
                self?.label.text = "Done."
                self?.loadingView.stopAnimating()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        observers.forEach { $0.cancel() }
    }
}
