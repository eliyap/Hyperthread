//
//  SummaryLine.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 21/11/21.
//

import UIKit

final class SpacedSeparator: UIView {
    
    private let insets: UIEdgeInsets

    private let thickness: CGFloat

    private let hairlineView = HairlineView()

    init(vertical: CGFloat, horizontal: CGFloat, thickness: CGFloat = 1) {
        self.thickness = thickness
        self.insets = UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
        super.init(frame: .zero)
        addSubview(hairlineView)
    }

    public func constrain(to view: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor),
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            heightAnchor.constraint(equalToConstant: insets.top + insets.bottom + thickness),
        ])
        hairlineView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hairlineView.leftAnchor.constraint(equalTo: leftAnchor, constant: insets.left),
            hairlineView.rightAnchor.constraint(equalTo: rightAnchor, constant: -insets.right),
            hairlineView.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            hairlineView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom),
        ])
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class HairlineView: UIView {
    
    init() {
        super.init(frame: .zero)
        backgroundColor = .separator
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SummaryView: UIStackView {

    public let timestampButton = TimestampButton()

    init() {
        super.init(frame: .zero)
        axis = .horizontal
        distribution = .fill
        alignment = .center
        
        translatesAutoresizingMaskIntoConstraints = false

        addArrangedSubview(timestampButton)
    }

    func configure(_ discussion: Discussion) {
        timestampButton.configure(discussion)
    }
    
    required init(coder: NSCoder) {
        fatalError("No.")
    }
}
