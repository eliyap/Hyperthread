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
    
    public private(set) var dds: DDS! = nil
    
    public private(set) var discussion: Discussion? = nil
    
    private var observers = Set<AnyCancellable>()
    
    typealias DDS = NodeDDS
    
    public weak var requester: DiscusssionRequestable?
    
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
        dds = .init(discussion: discussion, tableView: tableView, cellProvider: cellProvider)
        
        configure(tableView: tableView)
    }
    
    /// Aesthetic setup work.
    private func configure(tableView: UITableView) -> Void {
        /// Simple hack to remove top separator line (which typically sits above the `CardHeaderCell`).
        /// Source: https://stackoverflow.com/questions/32668797/how-to-remove-first-cell-top-separator-and-last-cell-bottom-separator
        tableView.tableHeaderView = UIView()
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
            if requester == nil {
                TableLog.error("Nil requester when constructing cell!")
                assert(false)
            }

            cell.configure(node: node, realm: realm, requester: requester)

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
    
    /// For our convenience.
    typealias Snapshot = NSDiffableDataSourceSnapshot<TweetSection, Node>
    
    private var nodes: [Node] = []
    
    init(
        discussion: Discussion?,
        tableView: UITableView,
        cellProvider: @escaping CellProvider
    ) {
        super.init(tableView: tableView, cellProvider: cellProvider)
        
        var snapshot = Snapshot()
        if let discussion = discussion {
            discussion.makeTree().assemble(&nodes)
            
            snapshot.appendSections([.root, .discussion])
            snapshot.appendItems([nodes[0]], toSection: .root)
            snapshot.appendItems(Array(nodes[1...]), toSection: .discussion)
        }
        self.apply(snapshot, animatingDifferences: false)
    }
    
    func firstIndexPath(where predicate: (Node) -> Bool) -> IndexPath? {
        guard let index = nodes.firstIndex(where: predicate) else {
            return nil
        }
        
        /// Account for split sections.
        if index == 0 {
            return IndexPath(row: 0, section: TweetSection.root.rawValue)
        } else {
            return IndexPath(row: index - 1, section: TweetSection.discussion.rawValue)
        }
    }
    
    deinit { }
}

extension DiscussionTable {
    @discardableResult
    func scrollToTweetWithID(_ tweetID: Tweet.ID) -> Bool {
        let path = dds.firstIndexPath(where: {$0.id == tweetID})
        guard let path = path else {
            TableLog.error("Could not locate path for id \(tweetID)")
            return false
        }

        tableView.scrollToRow(at: path, at: .none, animated: true)
        tableView.selectRow(at: path, animated: false, scrollPosition: .none)
        
        return true
    }
}
