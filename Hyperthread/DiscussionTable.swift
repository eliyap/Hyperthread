//
//  DiscussionTable.swift
//  Hyperthread
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
    
    private let realm = makeRealm()
    
    private var dds: DDS! = nil
    
    public private(set) var discussion: Discussion? = nil
    
    private var observers = Set<AnyCancellable>()
    
    typealias DDS = NodeDDS
    
    private let airport: Airport = .init()
    
    init(loadingCarrier: UserMessageCarrier) {
        super.init(nibName: nil, bundle: nil)
        /// Immediately defuse unwrapped nil `dds`.
        spawnDDS(discussion: nil)
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
        dds = .init(discussion: discussion, airport: airport, tableView: tableView, cellProvider: cellProvider)
    }
    
    private func cellProvider(tableView: UITableView, indexPath: IndexPath, node: Node) -> UITableViewCell? {
        if indexPath == IndexPath(row: 0, section: 0) {
            /// Safety check.
            assert(node.tweet.id == discussion?.id, "Root tweet ID does not match discussion ID!")
            
            guard let cell = tableView.dequeueReusableCell(withIdentifier: CardHeaderCell.reuseID) as? CardHeaderCell else {
                fatalError("Failed to create or cast new cell!")
            }
            guard case let .available(rootTweet, rootTweetAuthor) = node.tweet else {
                fatalError("Missing root tweet!")
            }
            cell.configure(tweet: rootTweet, author: rootTweetAuthor, realm: realm)

            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TweetCell.reuseID) as? TweetCell else {
                fatalError("Failed to create or cast new cell!")
            }
            cell.configure(node: node, realm: realm)

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
    
    weak var airport: Airport!
    
    /// For our convenience.
    typealias Snapshot = NSDiffableDataSourceSnapshot<TweetSection, Node>
    
    init(
        discussion: Discussion?,
        airport: Airport,
        tableView: UITableView, 
        cellProvider: @escaping CellProvider
    ) {
        self.airport = airport
        super.init(tableView: tableView, cellProvider: cellProvider)
        
        var snapshot = Snapshot()
        if let discussion = discussion {
            var flatTree = [Node]()
            discussion.makeTree(airport: airport).assemble(&flatTree)
            
            snapshot.appendSections([.root, .discussion])
            snapshot.appendItems([flatTree[0]], toSection: .root)
            snapshot.appendItems(Array(flatTree[1...]), toSection: .discussion)
        }
        self.apply(snapshot, animatingDifferences: false)
    }
    
    deinit { }
}
