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
    
    typealias DDS = TweetDDS
    
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
        tableView.register(CardCell.self, forCellReuseIdentifier: CardCell.reuseID)
        tableView.register(TweetCell.self, forCellReuseIdentifier: TweetCell.reuseID)
        dds = DDS(followingIDs: followingIDs, discussion: discussion, tableView: tableView) { [weak self] (tableView: UITableView, indexPath: IndexPath, tweet: Tweet) -> UITableViewCell? in
            let author = self!.realm.user(id: tweet.authorID)!
            if indexPath == IndexPath(row: 0, section: 0) {
                /// Safety check.
                assert(tweet.id == discussion?.id, "Root tweet ID does not match discussion ID!")
                
                guard let cell = tableView.dequeueReusableCell(withIdentifier: CardCell.reuseID) as? CardCell else {
                    fatalError("Failed to create or cast new cell!")
                }
                cell.configure(tweet: tweet, author: author, realm: self!.realm)

                return cell
            } else {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: TweetCell.reuseID) as? TweetCell else {
                    fatalError("Failed to create or cast new cell!")
                }
                cell.configure(tweet: tweet, author: author, realm: self!.realm)

                return cell
            }
        }
        
        var arr = [Node]()
        discussion?.makeTree().assemble(&arr)
        print(arr)
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
        if let discussion = discussion {
            snapshot.appendSections([.root, .discussion])
            snapshot.appendItems([realm.tweet(id: discussion.id)!], toSection: .root)
            snapshot.appendItems(discussion.relevantTweets(followingUserIDs: followingIDs), toSection: .discussion)
        }
        self.apply(snapshot, animatingDifferences: false)
    }
    
    deinit {
        if let token = token {
            token.invalidate()
        }
    }
}
