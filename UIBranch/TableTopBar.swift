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
    
    enum Duration {
        case indefinite
        case interval(TimeInterval)
    }
    
    /// Whether this notification should stick around indefinitely until replaced.
    let duration: Duration
}

final class TableTopBar: UIVisualEffectView {

    private let barContents: BarContents = .init()
    
    private var observers: Set<AnyCancellable> = []
    private var heightConstraint: NSLayoutConstraint? = nil
    private let loadingConduit: UserMessageConduit

    init(loadingConduit: UserMessageConduit) {
        self.loadingConduit = loadingConduit
        super.init(effect: UIBlurEffect(style: .systemMaterial))

        contentView.addSubview(barContents)
        barContents.isHidden = true
        
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

    public func setState(_ message: UserMessage?) -> Void {
        /// Set message to expire after the passed duration.
        if
            let duration = message?.duration,
            case .interval(let timeInterval) = duration
        {
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeInterval) { [weak self] in
                self?.loadingConduit.send(nil)
            }
        }
        
        /// UI code **must** run on the main thread!
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                TableLog.error("Nil self in \(Self.description())")
                assert(false)
                return
            }
            UIView.transition(with: self.barContents, duration: 0.25, options: .transitionCrossDissolve) {
                if let message = message {
                    self.barContents.isHidden = false
                    self.barContents.configure(category: message.category)
                    let inset = CardTeaserCell.borderInset
                    self.barContents.layoutMargins = .init(top: inset, left: inset, bottom: inset, right: inset)
                } else {
                    self.barContents.isHidden = true
                    self.barContents.layoutMargins = .zero
                }
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
    
    public func configure(category: UserMessage.Category) -> Void {
        switch category {

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
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
