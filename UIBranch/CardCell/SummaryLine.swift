//
//  SummaryLine.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 21/11/21.
//

import UIKit

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
