//
//  DiscussionTable.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 13/11/21.
//

import UIKit
import RealmSwift
import Twig

enum TweetSection: Int {
    /// The only section, for now.
    case Main
}

final class DiscussionTable: UITableViewController {
    
    /// Freeze fetch so that there is no ambiguity.
    private let followingIDs = UserDefaults.groupSuite.followingIDs
    
    private let realm = try! Realm()
    
    private var dds: DDS! = nil
    
    public private(set) var discussion: Discussion? = nil
    
    typealias Cell = TweetCell
    typealias DDS = TweetDDS
    
    init() {
        super.init(nibName: nil, bundle: nil)
        /// Immediately defuse unwrapped nil `dds`.
        spawnDDS(discussion: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("No.")
    }
    
    private func spawnDDS(discussion: Discussion?) {
        self.tableView = UITableView()
        tableView.register(Cell.self, forCellReuseIdentifier: Cell.reuseID)
        dds = DDS(followingIDs: followingIDs, discussion: discussion, tableView: tableView) { [weak self] (tableView: UITableView, indexPath: IndexPath, tweet: Tweet) -> UITableViewCell? in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseID) as? Cell else {
                fatalError("Failed to create or cast new cell!")
            }
            let author = self!.realm.user(id: tweet.authorID)!
            cell.configure(tweet: tweet, author: author, realm: self!.realm)

            // TODO: populate cell with discussion information
            return cell
        }
    }
}

extension DiscussionTable: SplitDelegate {
    func present(_ discussion: Discussion) -> Void {
        /// - Note: setting the `discussion` alerts ancestor `UISplitViewController` to prefer
        ///   the secondary view when collapsing.
        self.discussion = discussion
        
        self.tableView = UITableView()
        spawnDDS(discussion: discussion)
    }
}

final class TweetDDS: UITableViewDiffableDataSource<TweetSection, Tweet> {
    private let realm = try! Realm()
    private var token: NotificationToken! = nil

    /// For our convenience.
    typealias Snapshot = NSDiffableDataSourceSnapshot<TweetSection, Tweet>
    
    init(
        followingIDs: [User.ID]?,
        discussion: Discussion?, 
        tableView: UITableView, 
        cellProvider: @escaping CellProvider
    ) {
        super.init(tableView: tableView, cellProvider: cellProvider)
        /// Immediately defuse unwrapped nil.
        token = discussion?.observe { change in
            switch change {
            case .change(let object, let properties):
                break
            case .deleted:
                break
            case .error(let error):
                fatalError("\(error)")
            }
        }
        
        var snapshot = Snapshot()
        snapshot.appendSections([.Main])
        snapshot.appendItems(discussion?.relevantTweets(followingUserIDs: followingIDs) ?? [])
        self.apply(snapshot, animatingDifferences: false)
    }
    
    deinit {
        if let token = token {
            token.invalidate()
        }
    }
}