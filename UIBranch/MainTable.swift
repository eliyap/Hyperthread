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
    private lazy var airport = { Airport(credentials: Auth.shared.credentials!) }()

    private let realm = try! Realm()
    var discussions: Results<Discussion>
    
    private var dds: DDS! = nil
    
    /// Object to notify when something elsewhere in the `UISplitViewController` should change.
    private weak var splitDelegate: SplitDelegate!
    
    typealias DDS = DiscussionDDS
    typealias Cell = TweetCell
    
    init(splitDelegate: SplitDelegate) {
        self.splitDelegate = splitDelegate
        self.discussions = realm.objects(Discussion.self)
            .sorted(by: \Discussion.id, ascending: false)
        super.init(nibName: nil, bundle: nil)
        /// Immediately defuse unwrapped nil `dds`.
        dds = DDS(tableView: tableView) { [weak self] (tableView: UITableView, indexPath: IndexPath, discussion: Discussion) -> UITableViewCell? in
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
        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped)),
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addTapped3)),
            UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(addTapped2)),
        ]
        
        /// Enable self sizing table view cells.
        tableView.estimatedRowHeight = 100
    }
    
    @objc
    func addTapped() {
        Task {
            await fetchOld(airport: airport, credentials: Auth.shared.credentials!)
        }
    }
    
    @objc
    func addTapped3() {
        Task {
            await fetchNew(airport: airport, credentials: Auth.shared.credentials!)
        }
    }
    
    @objc
    func addTapped2() {
        Task {
            await updateFollowing(credentials: Auth.shared.credentials!)
        }
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

    /// For our convenience.
    typealias Snapshot = NSDiffableDataSourceSnapshot<DiscussionSection, Discussion>

    override init(tableView: UITableView, cellProvider: @escaping CellProvider) {
        #warning("TODO: sort by date instead.")
        let results = realm.objects(Discussion.self)
            .sorted(by: \Discussion.id, ascending: false)
        
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

final class TweetCell: UITableViewCell {
    
    public static let reuseID = "DiscussionCell"
    override var reuseIdentifier: String? { Self.reuseID }
    
    /// Component Views
    let stackView = UIStackView()
    let replyView = ReplyView()
    let userView = UserView()
    let tweetLabel = UILabel()
    let retweetView = RetweetView()
    // TODO: add profile image
    // TODO: add retweet marker
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        /// Configure Main Stack View
        contentView.addSubview(stackView)
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])

        stackView.addArrangedSubview(replyView)
        stackView.addArrangedSubview(userView)
        stackView.addArrangedSubview(tweetLabel)
        stackView.addArrangedSubview(retweetView)

        /// Configure Label
        tweetLabel.font = UIFont.preferredFont(forTextStyle: .body)
        tweetLabel.adjustsFontForContentSizeCategory = true

        /// Allow tweet to wrap across lines.
        tweetLabel.lineBreakMode = .byWordWrapping
        tweetLabel.numberOfLines = 0 /// Yes, really.
    }

    public func configure(tweet: Tweet, author: User, realm: Realm) {
        userView.configure(user: author)
        tweetLabel.text = tweet.text
        replyView.configure(tweet: tweet, realm: realm)
        retweetView.configure(tweet: tweet, realm: realm)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class IconView: UIStackView {
    
    private let imageView = UIImageView()
    private let label = UILabel()
    
    init(sfSymbol: String, config: UIImage.SymbolConfiguration? = nil) {
        super.init(frame: .zero)
        
        /// Configure Main Stack View.
        axis = .horizontal
        alignment = .leading
        spacing = 4
        imageView.contentMode = .scaleAspectFit
        
        addArrangedSubview(imageView)
        addArrangedSubview(label)

        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        
        imageView.image = UIImage(systemName: sfSymbol)
        if let config = config {
            imageView.preferredSymbolConfiguration = config
        }

        // Mute Colors.
        imageView.tintColor = .secondaryLabel
        label.textColor = .secondaryLabel
    }

    public func setText(to text: String) {
        label.text = text
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ReplyView: UIStackView {

    let replyLabel = IconView(sfSymbol: "arrowshape.turn.up.backward.fill")
    let quoteLabel = IconView(sfSymbol: "quote.bubble.fill")

    init() {
        super.init(frame: .zero)
        axis = .vertical
        spacing = 0
        alignment = .leading
        translatesAutoresizingMaskIntoConstraints = false
        
        addArrangedSubview(replyLabel)
        addArrangedSubview(quoteLabel)

        // temp
        replyLabel.setText(to: "Reply")
        quoteLabel.setText(to: "Quote")
    }
    
    func configure(tweet: Tweet, realm: Realm) -> Void {
        if let replyingID = tweet.replying_to {
            if
                let t = realm.tweet(id: replyingID),
                let handle = realm.user(id: t.authorID)?.handle
            {
                replyLabel.setText(to: "@" + handle)
            } else {
                Swift.debugPrint("Unable to lookup replied user")
                replyLabel.setText(to: "@[ERROR]")
            }
            replyLabel.isHidden = false
        } else {
            replyLabel.isHidden = true
        }
        
        if let quotingID = tweet.quoting {
            guard
                let t = realm.tweet(id: quotingID),
                let handle = realm.user(id: t.authorID)?.handle
            else { fatalError("Unable to lookup quoted user!") }
            quoteLabel.setText(to: "@" + handle)
            quoteLabel.isHidden = false
        } else {
            quoteLabel.isHidden = true
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class RetweetView: UIStackView {
    
    var retweetLabels: [IconView] = []

    init() {
        super.init(frame: .zero)
        axis = .vertical
        alignment = .leading
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func configure(tweet: Tweet, realm: Realm) {
        /// Clear existing labels.
        retweetLabels.forEach {
            removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        retweetLabels = []
        
        tweet.retweetedBy.forEach { userID in
            let user = realm.user(id: userID)!
            let label = IconView(sfSymbol: "arrow.2.squarepath", config: UIImage.SymbolConfiguration(weight: .black))
            label.setText(to: "@" + user.handle)
            retweetLabels.append(label)
            addArrangedSubview(label)
        }
    }
}

final class UserView: UIStackView {
    
    private let nameLabel = UILabel()
    private let handleLabel = UILabel()
    
    fileprivate let _spacing: CGFloat = 5

    init() {
        super.init(frame: .zero)
        axis = .horizontal
        alignment = .firstBaseline
        spacing = _spacing

        translatesAutoresizingMaskIntoConstraints = false
        
        addArrangedSubview(nameLabel)
        addArrangedSubview(handleLabel)

        nameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        nameLabel.adjustsFontForContentSizeCategory = true
        
        handleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        handleLabel.adjustsFontForContentSizeCategory = true
        handleLabel.textColor = .secondaryLabel
        
        /// Allow handle to be truncated if space is insufficient.
        /// We want this to be truncated before the username is.
        handleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    public func configure(user: User) {
        nameLabel.text = user.name
        handleLabel.text = "@" + user.handle
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
