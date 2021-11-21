//
//  SummaryLine.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 21/11/21.
//

import UIKit

final class HairlineView: UIView {
    private let inset: CGFloat
    init(inset: CGFloat) {
        self.inset = inset
        super.init(frame: .zero)
        backgroundColor = .separator
    }

    public func constrain(to guide: UILayoutGuide) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: inset),
            trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -inset),
            heightAnchor.constraint(equalToConstant: 1)
        ])
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class SummaryLine: UIStackView {

    let timestampButton = TimestampButton()

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
