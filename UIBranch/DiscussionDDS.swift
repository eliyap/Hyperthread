//
//  DiscussionDDS.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 16/1/22.
//

import Foundation
import RealmSwift

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
    
    
    init(realm: Realm, tableView: UITableView, cellProvider: @escaping CellProvider, restoreScroll: @escaping () -> ()) {
        self.realm = realm
        
        let results = realm.objects(Discussion.self)
            .filter(Discussion.minRelevancePredicate)
            .sorted(by: \Discussion.updatedAt, ascending: false)
        self.restoreScroll = restoreScroll
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
        
        if
            let numDiscussions = numDiscussions,
            (numDiscussions - indexPaths.max()!.row) < threshhold
        {
            TableLog.debug("Row \(indexPaths.max()!.row) requested, prefetching items...", print: true, true)
            Task {
                await fetchOldTweets()
            }
        }
    }
    
    @objc
    public func fetchOldTweets() async {
        /// Prevent hammering fetch operations.
        guard isFetching == false else { return }
        isFetching = true
        defer { isFetching = false }
        
        do {
            try await homeTimelineFetch(TimelineOldFetcher.self)
            await ReferenceCrawler.shared.performFollowUp()
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
        
        Task {
            do {
                try await homeTimelineFetch(TimelineNewFetcher.self)
                await ReferenceCrawler.shared.performFollowUp()
                
                /// Record fetch completion.
                UserDefaults.groupSuite.firstFetch = false
            } catch {
                NetLog.error("\(error)")
                assert(false)
#warning("Perform new refresh animation here.")
            }
            print("Silent Fetch Completed!")
        }
    }
    
    #if DEBUG
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
    #endif
}
