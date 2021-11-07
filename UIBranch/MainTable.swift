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
    
    typealias Cell = TweetCell
    
    init() {
        self.discussions = realm.objects(Discussion.self)
            .sorted(by: \Discussion.id, ascending: false)
        super.init(nibName: nil, bundle: nil)
        tableView.register(Cell.self, forCellReuseIdentifier: Cell.reuseID)
        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped)),
            UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(addTapped2)),
        ]
    }
    
    @objc
    func addTapped() {
        Task {
            await fetchOld(airport: airport, credentials: Auth.shared.credentials!)
        }
    }
    
    @objc
    func addTapped2() {
        Task {
            await updateFollowing(credentials: Auth.shared.credentials!)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("No.")
    }
}

// MARK: - `UITableViewDataSource` Conformance.
extension MainTable {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return discussions.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let discussion = discussions[section]
        return discussion.tweets.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseID, for: indexPath) as! Cell
        let tweet = discussions[indexPath.section].tweets[indexPath.row]
        cell.textLabel?.text = tweet.text
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return discussions[section].id
    }
}

final class TweetCell: UITableViewCell {
    
    public static let reuseID = "DiscussionCell"
    override var reuseIdentifier: String? { Self.reuseID }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
