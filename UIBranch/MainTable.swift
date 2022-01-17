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
    
    private let realm = try! Realm()
    
    private var mrd: MarkReadDaemon! = nil
    private var dds: DDS! = nil
    
    /// Object to notify when something elsewhere in the `UISplitViewController` should change.
    private weak var splitDelegate: SplitDelegate!
    
    typealias DDS = DiscussionDDS
    typealias Cell = CardTeaserCell
    
    private var observers = Set<AnyCancellable>()
    
    private var arrowView: ArrowRefreshView? = nil
    
    private let airport: Airport = .init()
    
    init(splitDelegate: SplitDelegate) {
        self.splitDelegate = splitDelegate
        super.init(nibName: nil, bundle: nil)
        
        /// Immediately defuse unwrapped nil `dds`.
        dds = DDS(
            realm: realm,
            tableView: tableView,
            cellProvider: cellProvider,
            restoreScroll: restoreScroll
        )
        
        /// Immediately defuse unwrapped nil `mrd`.
        mrd = MarkReadDaemon(token: dds.token)
        
        tableView.register(Cell.self, forCellReuseIdentifier: Cell.reuseID)
        
        /// Erase separators.
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        
        /// Enable self sizing table view cells.
        tableView.estimatedRowHeight = 100
        
        /// Enable pre-fetching.
        tableView.prefetchDataSource = dds
        
        /// Refresh timeline at app startup.
        #if !DEBUG /// Disabled for debugging.
        DDS.fetchNewTweets { /* do nothing */ }
        #endif
        
        /// Refresh timeline at login.
        Auth.shared.$state
            .dropFirst() /// Ignore publication that occurs on initialization, when loading from `UserDefaults`.
            .sink { [weak self] state in
                switch state {
                case .loggedIn:
                    #warning("TODO: mark all tweets read here.")
                    let dds = self?.dds
                    Task {
                        await dds?.fetchNewTweets()
                    }
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
            UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(debugMethod3)),
        ]
        #endif
        
        tableView.backgroundColor = .systemRed
    }
    
    @objc
    func debugMethod() {
        dds.fetchFakeTweet()
    }
    
    @objc
    func debugMethod2() {
        Task {
            await dds.fetchNewTweets()
        }
    }
    
    @objc
    func debugMethod3() {
        NOT_IMPLEMENTED()
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
        
        Task {
            await dds.fetchNewTweets()
            DispatchQueue.main.async { /// Ensure call on main thread.
                UIView.animate(withDuration: 0.25) { [weak self] in
                    self?.arrowView?.endRefreshing()
                    self?.tableView.setContentOffset(CGPoint(x: .zero, y: -offset), animated: true)
                }
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
    private func restoreScroll() -> Void {
        guard let tablePos = UserDefaults.groupSuite.scrollPosition else {
            TableLog.debug("Could not obtain saved scroll position!", print: true, true)
            return
        }
        
        let path = tablePos.indexPath
        guard path.row < tableView.numberOfRows(inSection: DiscussionSection.Main.rawValue) else {
            TableLog.error("Out of bounds index path! \(path)")
            return
        }
        TableLog.debug("Now scrolling to \(tablePos).", print: true, true)
        tableView.scrollToRow(at: path, at: .top, animated: false)
        tableView.contentOffset.y -= tablePos.offset
    }
}

enum DiscussionSection: Int {
    /// The only section, for now.
    case Main = 0
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
            /// Do not update the Table DDS, because it causes a weird animation.
            var tokens: [NotificationToken] = []
            if let token = dds.token { tokens.append(token) }
            
            try realm.writeWithToken(withoutNotifying: tokens) { token in
                /// Mark discussion as read.
                discussion.markRead(token)
            }
        } catch {
            TableLog.error("\(error)")
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
