//
//  ControlledCell.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 5/12/21.
//

import UIKit

/**
 A `UITableViewCell` which owns a `UIViewController`.
 Though this runs against the spirit of Cocoa, it is our method to include child View Controllers.
 
 - Note: treat `controller.view` as `contentView`,
         that is, add subviews to it and constrain against it.
 */
class ControlledCell: UITableViewCell {

    /// Internal view controller.
    public let controller = CellController()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        /// Add to hierarchy and pin edges.
        contentView.addSubview(controller.view)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            controller.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            controller.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            controller.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class CellController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
