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
    
    private var discussion: Discussion? = nil
    
    typealias Cell = TweetCell
    typealias DDS = TweetDDS
    
    init() {
        super.init(nibName: nil, bundle: nil)
        /// Immediately defuse unwrapped nil `dds`.
        dds = DDS(tableView: tableView) { [weak self] (tableView: UITableView, indexPath: IndexPath, tweet: Tweet) -> UITableViewCell? in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseID) as? Cell else {
                fatalError("Failed to create or cast new cell!")
            }
            let author = self!.realm.user(id: tweet.authorID)!
            cell.configure(tweet: tweet, author: author, realm: self!.realm)

            // TODO: populate cell with discussion information
            return cell
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("No.")
    }
}

final class TweetDDS: UITableViewDiffableDataSource<TweetSection, Tweet> {
    private let realm = try! Realm()
    private var token: NotificationToken! = nil

    /// For our convenience.
    typealias Snapshot = NSDiffableDataSourceSnapshot<TweetSection, Tweet>
    
    override init(tableView: UITableView, cellProvider: @escaping CellProvider) {
        super.init(tableView: tableView, cellProvider: cellProvider)
    }
}
