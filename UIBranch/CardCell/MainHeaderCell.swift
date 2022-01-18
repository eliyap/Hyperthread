//
//  MainHeaderCell.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 18/1/22.
//

import UIKit

final class MainHeaderCell: UITableViewCell {
    
    public static let reuseID = "MainHeaderCell"
    override var reuseIdentifier: String? { Self.reuseID }
    
    /// Component views.
    let cardBackground = CardBackground()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        /// Configure background.
        contentView.addSubview(cardBackground)
        cardBackground.constrain(to: contentView.safeAreaLayoutGuide)

        let label = UILabel()
        label.text = "Hello"
        contentView.addSubview(label)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
