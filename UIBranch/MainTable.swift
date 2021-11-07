//
//  MainTable.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 7/11/21.
//

import UIKit
import Twig
import RealmSwift

final class MainTable: UITableViewController {
    
    /// Laziness prevents attempting to load nil IDs.
    private lazy var airport = { Airport(credentials: Auth.shared.credentials!) }()

    let realm = try! Realm()
    var discussions: Results<Discussion>
    
    init() {
        self.discussions = realm.objects(Discussion.self)
            .sorted(by: \Discussion.id, ascending: false)
        super.init(nibName: nil, bundle: nil)
        tableView.register(DiscussionCell.self, forCellReuseIdentifier: DiscussionCell.reuseID)
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped))
    }
    
    @objc
    func addTapped() {
        Task {
            await fetchOld(airport: airport, credentials: Auth.shared.credentials!)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("No.")
    }
}

// MARK: - `UITableViewDataSource` Conformance.
extension MainTable {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discussions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DiscussionCell.reuseID, for: indexPath)
        return cell
    }
}

final class DiscussionCell: UITableViewCell {
    public static let reuseID = "DiscussionCell"
    override var reuseIdentifier: String? { Self.reuseID }
}
