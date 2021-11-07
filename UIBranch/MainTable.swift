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
        let cell = tableView.dequeueReusableCell(withIdentifier: DiscussionCell.reuseID, for: indexPath) as! DiscussionCell
        let id = discussions[indexPath.row].id
        cell.test(id: id)
        return cell
    }
}

final class DiscussionCell: UITableViewCell {
    
    private let stackView = UIStackView()
    private var table: DiscussionTable? = nil
    
    public static let reuseID = "DiscussionCell"
    override var reuseIdentifier: String? { Self.reuseID }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        /// Set up Stack View.
        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.widthAnchor.constraint(equalTo: contentView.widthAnchor),
            stackView.heightAnchor.constraint(equalTo: contentView.heightAnchor),
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
        stackView.axis = .vertical
        stackView.alignment = .leading
        
        /// Testing.
        stackView.backgroundColor = .systemPurple
        let label = UILabel()
        label.text = "LOL"
        stackView.addArrangedSubview(label)
    }
    
    func test(id: Tweet.ID) {
        /// Clear all subviews
        let svs = stackView.arrangedSubviews
        for v in svs {
            stackView.removeArrangedSubview(v)
            NSLayoutConstraint.deactivate(v.constraints)
            v.removeFromSuperview()
        }
        
        table = DiscussionTable(id)
        
        stackView.addArrangedSubview(table!.view)
        NSLayoutConstraint.activate([table!.view.widthAnchor.constraint(equalTo: stackView.widthAnchor)])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


final class DiscussionTable: UITableViewController {
    let realm = try! Realm()
    var tweets: [Tweet]
    
    init(_ discussionID: Tweet.ID) {
        tweets = realm.discussion(id: discussionID)!.tweets.sorted(by: {$0.id < $1.id})
        super.init(nibName: nil, bundle: nil)
        tableView.register(TweetCell.self, forCellReuseIdentifier: TweetCell.reuseID)
        tableView.bounces = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - `UITableViewDataSource` Conformance.
extension DiscussionTable {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweets.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: TweetCell.reuseID, for: indexPath)
        cell.textLabel?.text = "???"
        return cell
    }
}

final class TweetCell: UITableViewCell {
    
    public static let reuseID = "TweetCell"
    override var reuseIdentifier: String? { Self.reuseID }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.backgroundColor = .systemPink
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
