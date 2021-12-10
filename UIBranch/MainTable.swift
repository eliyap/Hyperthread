//
//  MainTable.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 7/11/21.
//

import UIKit
import Twig
import RealmSwift
import Combine

final class MainTable: UITableViewController {
    
    /// Laziness prevents attempting to load nil IDs.
    private let fetcher = Fetcher()

    private let realm = try! Realm()
    
    private var mrd: MarkReadDaemon! = nil
    private var dds: DDS! = nil
    
    /// Object to notify when something elsewhere in the `UISplitViewController` should change.
    private weak var splitDelegate: SplitDelegate!
    
    typealias DDS = DiscussionDDS
    typealias Cell = CardTeaserCell
    
    private var observers = Set<AnyCancellable>()
    
    private var arrowView: ArrowRefreshView? = nil
    
    init(splitDelegate: SplitDelegate) {
        self.splitDelegate = splitDelegate
        super.init(nibName: nil, bundle: nil)
        
        /// Immediately defuse unwrapped nil `dds`.
        dds = DDS(
            realm: realm,
            fetcher: fetcher,
            tableView: tableView,
            cellProvider: cellProvider,
            action: setScroll
        )
        
        /// Immediately defuse unwrapped nil `mrd`.
        mrd = MarkReadDaemon(token: dds.getToken())
        
        tableView.register(Cell.self, forCellReuseIdentifier: Cell.reuseID)
        
        /// Erase separators.
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        
        /// Enable self sizing table view cells.
        tableView.estimatedRowHeight = 100
        
        /// Enable pre-fetching.
        tableView.prefetchDataSource = fetcher
        
        /// Refresh timeline at app startup.
        #warning("Disabled startup refresh")
//        fetcher.fetchNewTweets { /* do nothing */ }
        
        /// Refresh timeline at login.
        Auth.shared.$state
            .dropFirst() /// Ignore publication that occurs on initialization, when loading from `UserDefaults`.
            .sink { [weak self] state in
                switch state {
                case .loggedIn:
                    #warning("Disabled startup refresh")
//                    self?.fetcher.fetchNewTweets { /* do nothing */ }
                    break
                default:
                    break
                }
            }
            .store(in: &observers)
        
        /// Configure Refresh.
        let arrow = ArrowRefreshView(scrollView: tableView, onRefresh: refresh)
        self.arrowView = arrow
        tableView.addSubview(arrow)
        arrow.constrain(to: tableView)
        
        /// DEBUG
        #if DEBUG
        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(debugMethod)),
            UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(debugMethod2)),
        ]
        #endif
        
        tableView.backgroundColor = .systemRed
    }
    
    @objc
    func debugMethod() {
        fetcher.fetchFakeTweet()
    }
    
    @objc
    func debugMethod2() {
        fetcher.fetchNewTweets { /* do nothing */ }
    }
    
    required init?(coder: NSCoder) {
        fatalError("No.")
    }
    
    @objc
    public func refresh() {
        let offset = self.getNavBarHeight() + self.getStatusBarHeight()
        
        UIView.animate(withDuration: 0.25) { [weak self] in
            self?.arrowView?.beginRefreshing()
            let bumped = -offset - 1.5 * ArrowRefreshView.offset
            self?.tableView.setContentOffset(CGPoint(x: .zero, y: bumped), animated: true)
        }
        
        fetcher.fetchNewTweets {
            UIView.animate(withDuration: 0.25) { [weak self] in
                self?.arrowView?.endRefreshing()
                self?.tableView.setContentOffset(CGPoint(x: .zero, y: -offset), animated: true)
            }
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        /// - Note: do not invoke `super`.
        let offset = scrollView.contentOffset.y + getNavBarHeight() + getStatusBarHeight()
        arrowView?.didScroll(offset: offset)
    }
    
    deinit {
        /// Cancel to prevent leak.
        observers.forEach { $0.cancel() }
    }
    
    /// Method that provides Diffable Data Source with cells.
    private func cellProvider(tableView: UITableView, indexPath: IndexPath, discussion: Discussion) -> UITableViewCell? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseID) as? Cell else {
            fatalError("Failed to create or cast new cell!")
        }
        let tweet = realm.tweet(id: discussion.id)!
        let author = realm.user(id: tweet.authorID)
        cell.configure(discussion: discussion, tweet: tweet, author: author, realm: realm)
        cell.resetStyle()
        mrd.associate(indexPath, with: discussion)
        
        return cell
    }
    
    /// Restores the saved scroll position.
    private func setScroll() -> Void {
        guard let tablePos = UserDefaults.groupSuite.scrollPosition else {
            TableLog.debug("Could not obtain saved scroll position!", print: true, true)
            return
        }
        
        let path = tablePos.indexPath
        guard path.row < tableView.numberOfRows(inSection: 0) else {
            TableLog.error("Out of bounds index path! \(path)")
            return
        }
        tableView.scrollToRow(at: path, at: .top, animated: false)
        tableView.contentOffset.y -= tablePos.offset
    }
}

enum DiscussionSection: Int {
    /// The only section, for now.
    case Main
}

final class DiscussionDDS: UITableViewDiffableDataSource<DiscussionSection, Discussion> {
    private let realm: Realm
    private var token: NotificationToken! = nil

    private let fetcher: Fetcher
    
    private let scrollAction: () -> ()
    
    /// For our convenience.
    typealias Snapshot = NSDiffableDataSourceSnapshot<DiscussionSection, Discussion>

    init(realm: Realm, fetcher: Fetcher, tableView: UITableView, cellProvider: @escaping CellProvider, action: @escaping () -> ()) {
        self.realm = realm
        
        let results = realm.objects(Discussion.self)
            .sorted(by: \Discussion.updatedAt, ascending: false)
        self.fetcher = fetcher
        self.scrollAction = action
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
                self.scrollAction()
                
            case .update(let results, deletions: let deletions, insertions: let insertions, modifications: let modifications):
                TableLog.debug("Update: \(results.count) discussions, \(deletions.count) deletions, \(insertions.count) insertions, \(modifications.count) modifications.", print: true, true)
                TableLog.debug("Insertion indices: \(insertions)", print: true, false)
                self.setContents(to: results, animated: false)
                
                /// Only restore scroll position if items were added to the top of the queue.
                if insertions.contains(0) {
                    self.scrollAction()
                }
                
            case .error(let error):
                fatalError("\(error)")
            } 
        }
    }

    fileprivate func setContents(to results: Results<Discussion>, animated: Bool) -> Void {
        var snapshot = Snapshot()
        snapshot.appendSections([.Main])
        snapshot.appendItems(Array(results), toSection: .Main)
        TableLog.debug("Snapshot contains \(snapshot.numberOfSections) sections and \(snapshot.numberOfItems) items.", print: true)
        apply(snapshot, animatingDifferences: animated)
        
        fetcher.numDiscussions = results.count
    }
    
    /// Accessor
    func getToken() -> NotificationToken {
        return self.token
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
        
        do {
            try realm.write(withoutNotifying: [dds.getToken()]) {
                /// Mark discussion as read.
                discussion.read = .read
                
                /// Patch updated date, as it can be flaky.
                discussion.patchUpdatedAt()
            }
        } catch {
            // TODO: log non-critical failure.
            assert(false, "\(error)")
        }

        /// Style cell.
        guard let cell = tableView.cellForRow(at: indexPath) else {
            TableLog.warning("`didSelect` Could not find cell at \(indexPath)")
            return
        }
        guard let cardCell = cell as? CardTeaserCell else {
            assert(false, "Could not cast cell to CardCell!")
            return
        }
        
        /// Only style if cell will stay on screen.
        if (splitViewController?.isCollapsed ?? true) == false {
            cardCell.style(selected: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        /// - Note: do not invoke super method here, as it causes a crash (21.11.21)
        
        /// Style cell.
        guard let cell = tableView.cellForRow(at: indexPath) else {
            TableLog.warning("`didDeselect` Could not find cell at \(indexPath)")
            return
        }
        guard let cardCell = cell as? CardTeaserCell else {
            assert(false, "Could not cast cell to CardCell!")
            return
        }
        cardCell.style(selected: false)
    }
    
    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        didStopScrolling()
    }
    
    /// Docs: https://developer.apple.com/documentation/uikit/uiscrollviewdelegate/1619436-scrollviewdidenddragging
    /// > `decelerate`:
    /// > - `true` if the scrolling movement will continue, but decelerate, after a touch-up gesture during a dragging operation.
    /// > - If the value is `false`, scrolling stops immediately upon touch-up.
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            didStopScrolling()
        }
        let offset = scrollView.contentOffset.y + getNavBarHeight() + getStatusBarHeight()
        arrowView?.didStopScrolling(offset: offset)
    }
    
    fileprivate func didStopScrolling() -> Void {
        markVisibleCells()
        saveScrollPosition()
    }
    
    fileprivate func markVisibleCells() -> Void {
        guard let paths = tableView.indexPathsForVisibleRows else {
            TableLog.warning("Could not get paths!")
            return
        }
        
        /// Only mark `read` if tweet is fully on screen.
        /// Perform writes as a batch operation.
        let visiblePaths = paths.filter { path in
            tableView.bounds.contains(tableView.rectForRow(at: path))
        }
        mrd.mark(visiblePaths)
    }
    
    fileprivate func saveScrollPosition() -> Void {
        guard let paths = tableView.indexPathsForVisibleRows else {
            TableLog.warning("Could not get paths!")
            return
        }
        
        guard let topPath = paths.first else {
            TableLog.warning("Empty paths!")
            return
        }

        let topOffset = offset(at: topPath)
        
        UserDefaults.groupSuite.scrollPosition = TableScrollPosition(indexPath: topPath, offset: topOffset)
    }
    
    /// Find the distance between the top of a cell at `path` and the bottom of the navigation bar.
    fileprivate func offset(at path: IndexPath) -> CGFloat {
        tableView.rectForRow(at: path).origin.y - tableView.contentOffset.y - getNavBarHeight() - getStatusBarHeight()
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
            TableLog.debug("Row \(indexPaths.max()!.row) requested, prefetching items...")
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
                NetLog.warning("Tried to load tweets with nil credentials!")
                return
            }
            
            /// Prevent repeated requests.
            isFetching = true
            
            /// Perform a simple `home_timelime` fetch.
            let maxID = UserDefaults.groupSuite.maxID
            guard let rawTweets = try? await timeline(credentials: credentials, sinceID: nil, maxID: maxID) else {
                NetLog.warning("Failed to fetch timeline!")
                return
            }
            if rawTweets.isEmpty {
                NetLog.debug("No new tweets found!", print: true)
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
            NetLog.debug("new MaxID: \(newMaxID ?? 0), previously \(maxID ?? "nil")")
        }
    }
    
    @objc
    public func fetchNewTweets(onFetched: @escaping () -> Void) {
        Task {
            guard let credentials = Auth.shared.credentials else {
                NetLog.warning("Tried to load tweets with nil credentials!")
                return
            }
            
            NetLog.debug("UserID is \(credentials.user_id)", print: false, true)
            
            /// Prevent repeated requests.
            isFetching = true
            
            /// Perform a simple `home_timelime` fetch.
            let sinceID = UserDefaults.groupSuite.sinceID
            guard let rawTweets = try? await timeline(credentials: credentials, sinceID: sinceID, maxID: nil) else {
                NetLog.warning("Failed to fetch timeline!")
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
            NetLog.debug("new SinceID: \(newSinceID ?? 0), previously \(sinceID ?? "nil")")
            
            onFetched()
        }
    }
    
    /// DEBUG FUNCTION
    public func fetchFakeTweet() {
        let realm = try! Realm()
        try! realm.write {
            let t = Tweet.generateFake()
            realm.add(t)
            let c = Conversation(id: t.conversation_id)
            c.insert(t)
            realm.add(c)
            let d = Discussion(root: c)
            realm.add(d)
            
            /// Note a new discussion above the fold.
            UserDefaults.groupSuite.incrementScrollPositionRow()
        }
    }
}
