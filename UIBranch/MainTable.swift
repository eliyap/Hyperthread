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
    private let fetcher = Fetcher()

    private let realm = try! Realm()
    
    private var dds: DDS! = nil
    
    /// Object to notify when something elsewhere in the `UISplitViewController` should change.
    private weak var splitDelegate: SplitDelegate!
    
    typealias DDS = DiscussionDDS
    typealias Cell = TweetCell
    
    init(splitDelegate: SplitDelegate) {
        self.splitDelegate = splitDelegate
        super.init(nibName: nil, bundle: nil)
        /// Immediately defuse unwrapped nil `dds`.
        dds = DDS(fetcher: fetcher, tableView: tableView) { [weak self] (tableView: UITableView, indexPath: IndexPath, discussion: Discussion) -> UITableViewCell? in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseID) as? Cell else {
                fatalError("Failed to create or cast new cell!")
            }
            let tweet = self!.realm.tweet(id: discussion.id)!
            let author = self!.realm.user(id: tweet.authorID)!
            cell.configure(tweet: tweet, author: author, realm: self!.realm)

            // TODO: populate cell with discussion information
            return cell
        }
        
        tableView.register(Cell.self, forCellReuseIdentifier: Cell.reuseID)
        
        /// Enable self sizing table view cells.
        tableView.estimatedRowHeight = 100
        
        /// Enable pre-fetching.
        tableView.prefetchDataSource = fetcher
    }
    
    required init?(coder: NSCoder) {
        fatalError("No.")
    }
}

enum DiscussionSection: Int {
    /// The only section, for now.
    case Main
}

final class DiscussionDDS: UITableViewDiffableDataSource<DiscussionSection, Discussion> {
    private let realm = try! Realm()
    private var token: NotificationToken! = nil

    private let fetcher: Fetcher
    
    /// For our convenience.
    typealias Snapshot = NSDiffableDataSourceSnapshot<DiscussionSection, Discussion>

    init(fetcher: Fetcher, tableView: UITableView, cellProvider: @escaping CellProvider) {
        let results = realm.objects(Discussion.self)
            .sorted(by: \Discussion.updatedAt, ascending: false)
        self.fetcher = fetcher
        super.init(tableView: tableView, cellProvider: cellProvider)
        /// Immediately register token.
        token = results.observe { [weak self] (changes: RealmCollectionChange) in
            guard let self = self else { 
                assert(false, "No self!")
                return 
            }
            switch changes {
            case .initial(let results):
                self.setContents(to: results, animated: false)
                
            case .update(let results, deletions: let deletions, insertions: let insertions, modifications: let modifications):
                print("Update: \(results.count) tweets, \(deletions.count) deletions, \(insertions.count) insertions, \(modifications.count) modifications.")
                self.setContents(to: results, animated: true)
            
            case .error(let error):
                fatalError("\(error)")
            } 
        }
    }

    fileprivate func setContents(to results: Results<Discussion>, animated: Bool) -> Void {
        var snapshot = Snapshot()
        snapshot.appendSections([.Main])
        snapshot.appendItems(Array(results), toSection: .Main)
        Swift.debugPrint("Snapshot contains \(snapshot.numberOfSections) sections and \(snapshot.numberOfItems) items.")
        apply(snapshot, animatingDifferences: animated)
        
        fetcher.numDiscussions = results.count
    }
}

// MARK: - `UITableViewDelegate` Conformance
extension MainTable {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let discussion = dds.itemIdentifier(for: indexPath) else {
            fatalError("Could not find discussion from row!")
        }
        
        /**
         In compact width mode, it seems the `.secondary` view controller in `UISplitViewController` is lazily loaded,
         so the delegate's `splitController` can be `nil`.
         Therefore, as the active view we need to push the detail view onto the stack before calling `present`.
         */
        assert(splitViewController != nil, "Could not find ancestor split view!")
        splitViewController?.show(.secondary)
        
        splitDelegate.present(discussion)
    }
}

final class Fetcher: NSObject, UITableViewDataSourcePrefetching {
    
    public var numDiscussions: Int? = nil
    private(set) var isFetching = false
    private let threshhold = 25
    
    /// Laziness prevents attempting to load nil IDs.
    public lazy var airport = { Airport(credentials: Auth.shared.credentials!) }()
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) -> Void {
        if
            isFetching == false,
            let numDiscussions = numDiscussions,
            (numDiscussions - indexPaths.max()!.row) < threshhold
        {
            TableLog.log(items: "Row \(indexPaths.max()!.row) requested, prefetching items...")
            fetchOldTweets()
        }
    }
    
    /**
     
     - Note: there is a limitation on history depth.
       > Up to 800 Tweets are obtainable on the home timeline
     - Docs: https://developer.twitter.com/en/docs/twitter-api/v1/tweets/timelines/api-reference/get-statuses-home_timeline
     
     Therefore, if the v1 `home_timeline` API returns 0 results, do not allow further *backwards* fetches (this session).
     */
    @objc
    public func fetchOldTweets() {
        Task {
            guard let credentials = Auth.shared.credentials else {
                assert(false, "Tried to load tweets with nil credentials!")
            }
            
            /// Prevent repeated requests.
            isFetching = true
            
            /// Perform a simple `home_timelime` fetch.
            let maxID = UserDefaults.groupSuite.maxID
            guard let rawTweets = try? await timeline(credentials: credentials, sinceID: nil, maxID: maxID) else {
                Swift.debugPrint("Failed to fetch timeline!")
                return
            }
            if rawTweets.isEmpty {
                NetLog.log(items: "No new tweets found!")
            } else {
                /// Allow further requests.
                isFetching = false
            }
            
            /// Send to airport for further fetching.
            let ids = rawTweets.map{"\($0.id)"}
            airport.enqueue(ids)
            
            /// Update boundaries.
            let newMaxID = min(rawTweets.map(\.id).min(), Int64?(maxID))
            UserDefaults.groupSuite.maxID = newMaxID.string
            Swift.debugPrint("newMaxID \(newMaxID ?? 0), previously \(maxID ?? "")")
            Swift.debugPrint(rawTweets.map(\.id))
        }
    }
    
    @objc
    public func fetchNewTweets() {
        Task {
            guard let credentials = Auth.shared.credentials else {
                assert(false, "Tried to load tweets with nil credentials!")
            }
            
            /// Prevent repeated requests.
            isFetching = true
            
            /// Perform a simple `home_timelime` fetch.
            let sinceID = UserDefaults.groupSuite.sinceID
            guard let rawTweets = try? await timeline(credentials: credentials, sinceID: sinceID, maxID: nil) else {
                Swift.debugPrint("Failed to fetch timeline!")
                return
            }
            /// Allow further requests.
            isFetching = false
            
            /// Send to airport for further fetching.
            let ids = rawTweets.map{"\($0.id)"}
            airport.enqueue(ids)
            
            /// Update boundaries.
            let newSinceID = max(rawTweets.map(\.id).max(), Int64?(sinceID))
            UserDefaults.groupSuite.sinceID = newSinceID.string
            Swift.debugPrint("newSinceID \(newSinceID ?? 0)")
        }
    }
}
