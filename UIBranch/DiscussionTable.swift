//
//  DiscussionTable.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 13/11/21.
//

import UIKit
import RealmSwift
import Twig
import Combine

enum TweetSection: Int {
    /// The root tweet.
    case root
    
    /// Discussion flowing from the root tweet.
    case discussion
}

final class DiscussionTable: UITableViewController {
    
    /// Freeze fetch so that there is no ambiguity.
    private var followingIDs = Following.shared.ids
    
    private let realm = try! Realm()
    
    private var dds: DDS! = nil
    
    public private(set) var discussion: Discussion? = nil
    
    private var observers = Set<AnyCancellable>()
    
    typealias DDS = NodeDDS
    
    init() {
        super.init(nibName: nil, bundle: nil)
        /// Immediately defuse unwrapped nil `dds`.
        spawnDDS(discussion: nil)
        
        Following.shared.$ids
            .assign(to: \DiscussionTable.followingIDs, on: self)
            .store(in: &observers)
    }
    
    required init?(coder: NSCoder) {
        fatalError("No.")
    }
    
    /// Create a new Diffable Data Source and new UITableView
    /// to present the new Discussion.
    ///
    /// From the docs:
    /// >  If the table view needs a new data source after you configure it initially,
    /// > create and configure a new table view and diffable data source.
    ///
    /// Docs: https://developer.apple.com/documentation/uikit/uitableviewdiffabledatasource
    private func spawnDDS(discussion: Discussion?) {
        self.tableView = UITableView()
        tableView.register(CardHeaderCell.self, forCellReuseIdentifier: CardHeaderCell.reuseID)
        tableView.register(TweetCell.self, forCellReuseIdentifier: TweetCell.reuseID)
        dds = DDS(followingIDs: followingIDs, discussion: discussion, tableView: tableView, cellProvider: cellProvider)
    }
    
    private func cellProvider(tableView: UITableView, indexPath: IndexPath, node: Node) -> UITableViewCell? {
        let author = realm.user(id: node.tweet.authorID)!
        if indexPath == IndexPath(row: 0, section: 0) {
            /// Safety check.
            assert(node.tweet.id == discussion?.id, "Root tweet ID does not match discussion ID!")
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CardHeaderCell.reuseID) as? CardHeaderCell else {
                fatalError("Failed to create or cast new cell!")
            }
            cell.configure(tweet: node.tweet, author: author, realm: realm)

            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TweetCell.reuseID) as? TweetCell else {
                fatalError("Failed to create or cast new cell!")
            }
            cell.configure(node: node, author: author, realm: realm)

            return cell
        }
    }
    
    deinit {
        /// Cancel subscriptions so that they do not leak.
        observers.forEach { $0.cancel() }
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

final class NodeDDS: UITableViewDiffableDataSource<TweetSection, Node> {
    private let realm = try! Realm()
    private var token: NotificationToken! = nil

    /// For our convenience.
    typealias Snapshot = NSDiffableDataSourceSnapshot<TweetSection, Node>
    
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
                /// Discard values.
                (_, _) = (object, properties)
                break
            case .deleted:
                break
            case .error(let error):
                fatalError("\(error)")
            }
        }
        
        
        var snapshot = Snapshot()
        if let discussion = discussion {
            var flatTree = [Node]()
            discussion.makeTree().assemble(&flatTree)
            
            snapshot.appendSections([.root, .discussion])
            snapshot.appendItems([flatTree[0]], toSection: .root)
            snapshot.appendItems(Array(flatTree[1...]), toSection: .discussion)
        }
        self.apply(snapshot, animatingDifferences: false)
    }
    
    deinit {
        if let token = token {
            token.invalidate()
        }
    }
}
