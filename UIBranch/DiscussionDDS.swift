//
//  DiscussionDDS.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 16/1/22.
//

import Foundation
import RealmSwift
import Combine

final class DiscussionDDS: UITableViewDiffableDataSource<DiscussionSection, Discussion> {
    private let realm: Realm
    public private(set) var token: NotificationToken? = nil

    /// Restores scroll position in table.
    private let restoreScroll: () -> ()
    
    /// For our convenience.
    typealias Snapshot = NSDiffableDataSourceSnapshot<DiscussionSection, Discussion>

    /** `UITableViewDataSourcePrefetching` support. **/
    public var numDiscussions: Int? = nil /// Number of discussions in the table.
    private(set) var isFetching = false   /// Whether a fetch is currently occurring. Used to prevent duplicated fetches.
    {
        /// Relay `isFetching` status to user visible bar display.
        didSet {
            if isFetching {
                loadingConduit.send(.init(category: .loading, duration: .indefinite))
            } else {
                loadingConduit.send(.init(category: .loaded, duration: .interval(1.0)))
            }
        }
    }
    
#warning("Rework this hack!")
    /// Most recent date of an old timeline fetch. Goal is to prevent hammering the API. This is a hack workaround, and should be replaced.
    private var lastOldFetch: Date = .distantPast
    
    let loadingConduit: UserMessageConduit
    
    init(
        realm: Realm,
        tableView: UITableView,
        cellProvider: @escaping CellProvider,
        restoreScroll: @escaping () -> (),
        loadingConduit: UserMessageConduit
    ) {
        self.realm = realm
        
        let results = realm.objects(Discussion.self)
            .filter(Discussion.minRelevancePredicate)
            .sorted(by: \Discussion.updatedAt, ascending: false)
        self.restoreScroll = restoreScroll
        self.loadingConduit = loadingConduit
        
        super.init(tableView: tableView, cellProvider: cellProvider)
        /// Immediately register token.
        token = results.observe { [weak self] (changes: RealmCollectionChange) in
            guard let self = self else {
                assert(false, "No self!")
                return
            }
            
            /** - Note: `animated` is `false` so that when new tweet's are added via
                        "pull to refresh", the "inserted above" Twitterific-style effect is as
                        seamless as possible.
             */
            
            switch changes {
            case .initial(let results):
                /// Populate table without animation.
                self.setContents(to: results, animated: false)
                
                /// Restore scroll position from `UserDefaults`.
                self.restoreScroll()
                
            case .update(let results, deletions: let deletions, insertions: let insertions, modifications: let modifications):
                guard self.isFetching == false else {
                    Swift.debugPrint("Updated while fetching, ignoring update...")
                    return
                }
                #if DEBUG
                var report = ["MainTable: \(results.count) discussions"]
                if deletions.isNotEmpty { report.append("(-)\(deletions.count)")}
                if insertions.isNotEmpty { report.append("(+)\(insertions.count)")}
                if modifications.isNotEmpty { report.append("(~)\(modifications.count)")}
                TableLog.debug(report.joined(separator: ", "), print: true, true)
                
                TableLog.debug("Insertion indices: \(insertions)", print: true, false)
                #endif
                
                self.setContents(to: results, animated: true)
                if
                    /// Only scroll if tweets were added at the top!
                    insertions.contains(0),
                    /// We want to focus on "brand new" discussions, i.e. not stuff that happens to be old and unread.
                    /// To achieve this, we stop at the first `.read` `Discussion`.
                    let firstReadIndex = results.firstIndex(where: {$0.read == .read})
                {
                    tableView.scrollToRow(at: IndexPath(row: firstReadIndex, section: DiscussionSection.Main.rawValue), at: .top, animated: true)
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
        TableLog.debug("Snapshot contains \(snapshot.numberOfSections) sections and \(snapshot.numberOfItems) items.", print: false)
        apply(snapshot, animatingDifferences: animated)
        
        numDiscussions = results.count
    }
    
    deinit {
        token?.invalidate()
    }
}

extension DiscussionDDS: UITableViewDataSourcePrefetching {
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) -> Void {
        /// Number of rows left before we pull from Twitter.
        let threshhold = 25
        
        guard Date().timeIntervalSince(lastOldFetch) > TimeInterval.minute else {
            TableLog.debug("Too soon, denying prefetch.", print: true, true)
            return
        }
        if
            let numDiscussions = numDiscussions,
            (numDiscussions - indexPaths.max()!.row) < threshhold
        {
            Task {
                await fetchOldTweets()
            }
            lastOldFetch = Date()
        }
    }
    
    @objc
    public func fetchOldTweets() async {
        /// Prevent hammering fetch operations.
        guard isFetching == false else { return }
        isFetching = true
        defer { isFetching = false }
        
        TableLog.debug("Prefetching items...", print: true, true)
        
        do {
            try await homeTimelineFetch(TimelineOldFetcher.self)
            await ReferenceCrawler.shared.performFollowUp()
        } catch UserError.offline {
            loadingConduit.send(.init(category: .offline))
        } catch {
            NetLog.error("\(error)")
            assert(false)
        }
    }
    
    @objc
    public func fetchNewTweets() async {
        guard isFetching == false else { return }
        isFetching = true
        defer { isFetching = false }
        
        do {
            try await homeTimelineFetch(TimelineNewFetcher.self)
            await ReferenceCrawler.shared.performFollowUp()
            
            /// Record fetch completion.
            UserDefaults.groupSuite.firstFetch = false
        } catch UserError.offline {
            loadingConduit.send(.init(category: .offline))
        } catch {
            NetLog.error("\(error)")
            assert(false)
        }
    }
    
    #if DEBUG
    public func fetchFakeTweet() {
        let realm = try! Realm()
        try! realm.writeWithToken { token in
            let t = Tweet.generateFake()
            realm.add(t)
            let c = Conversation(id: t.conversation_id)
            c.insert(t, token: token)
            realm.add(c)
            let d = Discussion(root: c)
            realm.add(d)
            
            /// Note a new discussion above the fold.
            UserDefaults.groupSuite.incrementScrollPositionRow()
        }
    }
    #endif
}

fileprivate extension Discussion {
    /// - Warning: this exists as a workaround for `UITableViewDiffableDataSource`. Do _not_ use anywhere else!
    static let placeholder: Discussion = .init()
}
