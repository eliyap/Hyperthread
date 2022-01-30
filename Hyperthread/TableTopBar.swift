//
//  TableTopBar.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 18/1/22.
//

import Foundation
import UIKit
import Combine

/// A drop down bar that displays `UserMessage`s.
final class TableTopBar: UIVisualEffectView, Sendable {

    private let barContents: BarContents = .init()
    
    private var observers: Set<AnyCancellable> = []
    private var heightConstraint: NSLayoutConstraint? = nil
    private let loadingCarrier: UserMessageCarrier
    
    private static let AnimationDuration: TimeInterval = 0.2

    init(loadingCarrier: UserMessageCarrier) {
        self.loadingCarrier = loadingCarrier
        super.init(effect: UIBlurEffect(style: .systemMaterial))

        contentView.addSubview(barContents)
        barContents.isHidden = true
        Task {
            await loadingCarrier.register(callback: setState)
        }
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

        barContents.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            barContents.topAnchor.constraint(equalTo: topAnchor),
            barContents.bottomAnchor.constraint(equalTo: bottomAnchor),
            /// Keep stack contents away from notch / home indicator in iPhone X portrait mode.
            barContents.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor),
            barContents.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor),
            /// Keep stack centered and narrow.
            barContents.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
        ])
        
        /// Keep stack narrow.
        let narrow = barContents.widthAnchor.constraint(equalToConstant: .zero)
        narrow.priority = .defaultLow
        narrow.isActive = true
    }

    @MainActor /// Executes UI code.
    @Sendable
    public func setState(_ message: UserMessage?) -> Void {
        /// Set message to expire after the passed duration.
        if
            let duration = message?.duration,
            case .interval(let timeInterval) = duration
        {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 * timeInterval))
                await loadingCarrier.send(nil)
            }
        }
        
        UIView.transition(with: self.barContents, duration: Self.AnimationDuration, options: .transitionCrossDissolve) {
            self.barContents.display(message)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        observers.forEach { $0.cancel() }
    }
}

fileprivate final class BarContents: UIStackView {
    
    private let label: UILabel = .init()
    private let loadingView: UIActivityIndicatorView = .init()
    private let iconView: UIImageView = .init()
    
    /// Relay `isHidden` to component views.
    /// Helps avoid view margins remaining visible when they really shouldn't be.
    override var isHidden: Bool {
        didSet {
            label.isHidden = isHidden
            loadingView.isHidden = isHidden
            iconView.isHidden = isHidden
        }
    }
    
    lazy var inset = CardTeaserCell.borderInset
    
    @MainActor
    init() {
        super.init(frame: .zero)
        axis = .horizontal
        alignment = .center
        distribution = .equalSpacing
        spacing = inset
        
        isLayoutMarginsRelativeArrangement = true
        // layoutMargins = .init(top: inset, left: inset, bottom: inset, right: inset)

        addArrangedSubview(iconView)
        addArrangedSubview(label)
        addArrangedSubview(loadingView)
        
        iconView.preferredSymbolConfiguration = .init(textStyle: .body)
            .applying(UIImage.SymbolConfiguration(paletteColors: [.label]))
        iconView.contentMode = .scaleAspectFit

        loadingView.hidesWhenStopped = true
    }
    
    /// Display the user message.
    public func display(_ message: UserMessage?) -> Void {
        if let message = message {
            isHidden = false
            configure(category: message.category)
            layoutMargins = .init(top: inset, left: inset, bottom: inset, right: inset)
        } else {
            isHidden = true
            layoutMargins = .zero
            
            /// Stop activity indicator in case it's still going.
            loadingView.stopAnimating()
        }
    }
    
    private func configure(category: UserMessage.Category) -> Void {
        switch category {

        case .loading:
            self.iconView.image = UIImage(systemName: "arrow.down.circle.fill")
            self.label.text = "Loading..."
            self.loadingView.startAnimating()

        case .loaded:
            self.iconView.image = UIImage(systemName: "checkmark.circle.fill")
            self.label.text = "Done"
            self.loadingView.stopAnimating()

        case .offline:
            self.iconView.image = UIImage(systemName: "wifi.slash")
            self.label.text = "Currently Offline"
            self.loadingView.stopAnimating()
            
        default:
            #warning("TODO")
            break
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
