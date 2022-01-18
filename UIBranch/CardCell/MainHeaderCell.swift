//
//  MainHeaderCell.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 18/1/22.
//

import UIKit

/// Currently unused...
final class MainHeaderCell: UITableViewCell {
    
    public static let reuseID = "MainHeaderCell"
    override var reuseIdentifier: String? { Self.reuseID }
    
    /// Component views.
    let cardBackground = CardBackground()
    let stackView = UIStackView()
    
    private lazy var inset: CGFloat = CardTeaserCell.borderInset
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        /// Configure background.
        contentView.addSubview(cardBackground)
        cardBackground.constrain(to: safeAreaLayoutGuide)

        /// Configure Main Stack View.
        contentView.addSubview(stackView)
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: inset * 2),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset * 2),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset * 2),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -inset * 2),
        ])

        
        let label = UILabel()
        label.text = "Hello"
        stackView.addArrangedSubview(label)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
