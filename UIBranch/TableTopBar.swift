//
//  TableTopBar.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 18/1/22.
//

import Foundation
import UIKit
import Combine

typealias UserMessageConduit = PassthroughSubject<UserMessage?, Never>

internal struct UserMessage {
    
    enum Category {
        case loading
        case loaded
        case userError(UserError)
        case otherError(Error)
    }
    let category: Category
    
    /// Whether this notification should stick around indefinitely until replaced.
    let persistent: Bool
}

final class TableTopBar: UIVisualEffectView {
    
    private let stackView: UIStackView = .init()
    private let label: UILabel = .init()
    private let loadingView: UIActivityIndicatorView = .init()
    private let iconView: UIImageView = .init()
    
    private var observers: Set<AnyCancellable> = []
    private var heightConstraint: NSLayoutConstraint? = nil
    
    init(loadingConduit: UserMessageConduit) {
        super.init(effect: UIBlurEffect(style: .systemMaterial))
        
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
        
        heightConstraint = contentView.heightAnchor.constraint(equalToConstant: .zero)
        heightConstraint?.isActive = true
        
        label.setContentHuggingPriority(.required, for: .vertical)
        
        loadingConduit
            .sink { [weak self] in self?.setState($0) }
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
        
        let topMargin = stackView.topAnchor.constraint(lessThanOrEqualTo: topAnchor, constant: CardTeaserCell.borderInset)
        topMargin.priority = .defaultHigh
        topMargin.isActive = true
        let bottomMargin = stackView.bottomAnchor.constraint(greaterThanOrEqualTo: bottomAnchor, constant: -CardTeaserCell.borderInset)
        bottomMargin.priority = .defaultHigh
        bottomMargin.isActive = true
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(lessThanOrEqualTo: topAnchor, constant: CardTeaserCell.borderInset),
            stackView.bottomAnchor.constraint(greaterThanOrEqualTo: bottomAnchor, constant: -CardTeaserCell.borderInset),
            /// Keep stack contents away from notch / home indicator in iPhone X portrait mode.
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: CardTeaserCell.borderInset),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -CardTeaserCell.borderInset),
            /// Pin to label.
            label.topAnchor.constraint(equalTo: stackView.topAnchor),
            label.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
        ])
    }
    
    public func setState(_ message: UserMessage?) -> Void {
        /// UI code **must** run on the main thread!
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                TableLog.error("Nil self in \(Self.description())")
                assert(false)
                return
            }
            
            guard let message = message else {
                replace(object: self, on: \TableTopBar.heightConstraint, with: self.contentView.heightAnchor.constraint(equalToConstant: .zero))
                return
            }
            
            replace(object: self, on: \TableTopBar.heightConstraint, with: nil)
            
            switch message.category {
            
            case .loading:
                self.iconView.image = UIImage(systemName: "arrow.down.circle.fill")
                self.label.text = "Loading..."
                self.loadingView.startAnimating()
            
            case .loaded:
                self.iconView.image = UIImage(systemName: "checkmark.circle.fill")
                self.label.text = "Done."
                self.loadingView.stopAnimating()
            
            default:
                #warning("TODO")
                break
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
