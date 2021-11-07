//
//  MainTable.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 7/11/21.
//

import UIKit
import Twig

final class MainTable: UITableViewController {
    
    /// Laziness prevents attempting to load nil IDs.
    private lazy var airport = { Airport(credentials: Auth.shared.credentials!) }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
    }
    
    @objc
    func addTapped() {
        Task {
            await fetchNew(airport: airport, credentials: Auth.shared.credentials!)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("No.")
    }
}

