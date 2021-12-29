//
//  UserModalView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 29/12/21.
//

import Foundation
import UIKit

#warning("View Incomplete")
final class UserModalViewController: UIViewController {
    /**
    set up stack view, pin constraints,
    add username and handle label view, check for text scaling
    add following / not following button,
    hook up to realm stuff.
    */

    private let stackView: UIStackView

    #warning("TODO: add profile view")
    
    init() {
        self.stackView = .init()
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .automatic
        
        /// Configure `UIStackView`.
        view.addSubview(stackView)
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
