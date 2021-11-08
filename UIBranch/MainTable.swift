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

    private let realm = try! Realm()
    var discussions: Results<Discussion>
    
    /// Freeze fetch so that there is no ambiguity.
    private let followingIDs = UserDefaults.groupSuite.followingIDs
    
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
        
        /// Enable self sizing table view cells.
        tableView.estimatedRowHeight = 100
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
        return discussion.relevantTweets(followingUserIDs: followingIDs).count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseID, for: indexPath) as! Cell
        let tweet = discussions[indexPath.section].relevantTweets(followingUserIDs: followingIDs)[indexPath.row]
        let author = realm.user(id: tweet.authorID)!
        cell.configure(tweet: tweet, author: author)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return discussions[section].id
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        /// Enable self sizing table view cells.
        UITableView.automaticDimension
    }
}

final class TweetCell: UITableViewCell {
    
    public static let reuseID = "DiscussionCell"
    override var reuseIdentifier: String? { Self.reuseID }
    
    /// Component Views
    let stackView = UIStackView()
    let userView = UserView()
    let tweetLabel = UILabel()
    // TODO: add profile image
    // TODO: add retweet marker
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        /// Configure Main Stack View
        contentView.addSubview(stackView)
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])

        stackView.addArrangedSubview(userView)
        stackView.addArrangedSubview(tweetLabel)

        /// Configure Label
        tweetLabel.font = UIFont.preferredFont(forTextStyle: .body)
        tweetLabel.adjustsFontForContentSizeCategory = true

        /// Allow tweet to wrap across lines.
        tweetLabel.lineBreakMode = .byWordWrapping
        tweetLabel.numberOfLines = 0 /// Yes, really.
    }

    public func configure(tweet: Tweet, author: User) {
        userView.configure(user: author)
        tweetLabel.text = tweet.text
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class UserView: UIStackView {
    
    private let nameLabel = UILabel()
    private let handleLabel = UILabel()
    
    fileprivate let _spacing: CGFloat = 5

    init() {
        super.init(frame: .zero)
        axis = .horizontal
        alignment = .firstBaseline
        spacing = _spacing

        translatesAutoresizingMaskIntoConstraints = false
        
        addArrangedSubview(nameLabel)
        addArrangedSubview(handleLabel)

        nameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        nameLabel.adjustsFontForContentSizeCategory = true
        
        handleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        handleLabel.adjustsFontForContentSizeCategory = true
        handleLabel.textColor = .secondaryLabel
        
        /// Allow handle to be truncated if space is insufficient.
        /// We want this to be truncated before the username is.
        handleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    public func configure(user: User) {
        nameLabel.text = user.name
        handleLabel.text = "@" + user.handle
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
