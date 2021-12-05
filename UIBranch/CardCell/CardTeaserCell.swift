//
//  CardTeaserCell.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 21/11/21.
//

import UIKit
import RealmSwift
import Realm
import Twig

final class CardTeaserCell: ControlledCell {
    
    public static let reuseID = "CardTeaserCell"
    override var reuseIdentifier: String? { Self.reuseID }
    
    /// Component
    let cardBackground = CardBackground(inset: CardTeaserCell.borderInset)
    let stackView = UIStackView()
    let userView = UserView()
    let tweetTextView = TweetTextView()
    let retweetView = RetweetView()
    let hairlineView = SpacedSeparator(vertical: CardTeaserCell.borderInset, horizontal: CardTeaserCell.borderInset)
    let summaryView = SummaryView()
    // TODO: add profile image
    
    var token: NotificationToken? = nil
    
    public static let borderInset: CGFloat = 6
    private lazy var inset: CGFloat = CardTeaserCell.borderInset

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        /// Do not change color when selected.
        selectionStyle = .none
        backgroundColor = .flat

        /// Configure background.
        controller.view.addSubview(cardBackground)
        cardBackground.constrain(to: safeAreaLayoutGuide)

        /// Configure Main Stack View
        controller.view.addSubview(stackView)
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: inset * 2),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset * 2),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset * 2),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -inset * 2),
        ])

        stackView.addArrangedSubview(userView)
        stackView.addArrangedSubview(tweetTextView)
        stackView.addArrangedSubview(retweetView)
        stackView.addArrangedSubview(hairlineView)
        stackView.addArrangedSubview(summaryView)
        
        hairlineView.constrain(to: stackView)
        
        /// Manually constrain to full width.
        NSLayoutConstraint.activate([
            summaryView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            summaryView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
        ])

        let vc = YViewController()
        controller.addChild(vc)
        stackView.addArrangedSubview(vc.view)
        vc.didMove(toParent: controller)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vc.view.heightAnchor.constraint(equalToConstant: 100),
            vc.view.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
        ])

        /// Apply default styling.
        self.resetStyle()
    }

    public func configure(discussion: Discussion, tweet: Tweet, author: User, realm: Realm) {
        userView.configure(tweet: tweet, user: author, timestamp: tweet.createdAt)
        tweetTextView.attributedText = tweet.attributedString
        retweetView.configure(tweet: tweet, realm: realm)
        summaryView.configure(discussion, realm: realm)
        
        tweetTextView.delegate = self
        cardBackground.configure(status: discussion.read)
        
        /// Release old observer.
        if let token = token {
            token.invalidate()
        }
        
        /// Protect against error "Cannot register notification blocks from within write transactions."
        guard realm.isInWriteTransaction == false else {
            Swift.debugPrint("realm.isInWriteTransaction true, will cause crash!")
            return
        }
        token = discussion.observe(updateReadIcon)
    }
    
    /// Update color when `readStatus` changes.
    private func updateReadIcon(_ change: ObjectChange<RLMObjectBase>) -> Void {
        guard case let .change(_, properties) = change else { return }
        if let readChange = properties.first(where: {$0.name == Discussion.readStatusPropertyName}) {
            guard let newValue = readChange.newValue as? ReadStatus.RawValue else {
                Swift.debugPrint("Error: unexpected type! \(type(of: readChange.newValue))")
                return
            }
            guard let newRead = ReadStatus(rawValue: newValue) else {
                assert(false, "Invalid String!")
                return
            }
            cardBackground.configure(status: newRead)
        }
        if let updatedAtChange = properties.first(where: {$0.name == Discussion.updatedAtPropertyName}) {
            guard let newDate = updatedAtChange.newValue as? Date else {
                Swift.debugPrint("Error: unexpected type! \(type(of: updatedAtChange.newValue))")
                return
            }
            summaryView.timestampButton.configure(newDate)
        }
    }
    
    func style(selected: Bool) -> Void {
        UIView.animate(withDuration: 0.25) { [weak self] in
            guard let self = self else {
                assert(false, "self is nil")
                return
            }
            /// By changing the radius, offset, and transform at the same time, we can grow / shrink the shadow in place,
            /// creating a "lifting" illusion.
            if selected {
                self.styleSelected()
            } else {
                self.resetStyle()
            }
        }
    }
    
    public func styleSelected() -> Void {
        let shadowSize = self.inset * 0.75
        
        stackView.transform = CGAffineTransform(translationX: 0, y: -shadowSize)
        cardBackground.transform = CGAffineTransform(translationX: 0, y: -shadowSize)
        cardBackground.layer.shadowColor = UIColor.black.cgColor
        cardBackground.layer.shadowOpacity = 0.3
        cardBackground.layer.shadowRadius = shadowSize
        cardBackground.layer.shadowOffset = CGSize(width: .zero, height: shadowSize)
        
        cardBackground.backgroundColor = .cardSelected
        cardBackground.layer.borderWidth = 0
        cardBackground.layer.borderColor = UIColor.secondarySystemFill.cgColor
    }
    
    public func resetStyle() -> Void {
        stackView.transform = CGAffineTransform(translationX: 0, y: 0)
        cardBackground.transform = CGAffineTransform(translationX: 0, y: 0)
        cardBackground.layer.shadowColor = UIColor.black.cgColor
        cardBackground.layer.shadowOpacity = 0
        cardBackground.layer.shadowRadius = 0
        cardBackground.layer.shadowOffset = CGSize.zero
        
        cardBackground.backgroundColor = .card
        cardBackground.layer.borderWidth = 1.00
        cardBackground.layer.borderColor = UIColor.secondarySystemFill.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        token?.invalidate()
        TableLog.debug("\(Self.description()) de-initialized.", print: true, true)
    }
}

/**
 Re-direct URL taps to open link in Safari.
 */
extension CardTeaserCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL)
        return false
    }
}

func randomCGFloat() -> CGFloat {
    return CGFloat(arc4random()) / CGFloat(UInt32.max)
}

func randomColor() -> UIColor {
    return UIColor(red: randomCGFloat(), green: randomCGFloat(), blue: randomCGFloat(), alpha: 1)
}


//
//  ViewController.swift
//  PageViewController
//
//  Created by Miguel Fermin on 5/8/17.
//  Copyright © 2017 MAF Software LLC. All rights reserved.
//
//import UIKit

class YViewController: UIViewController {
    
    var viewControllers: [UIViewController]!
    var pageViewController: UIPageViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageController()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setupPageController() {
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        pageViewController.delegate = self
        
        viewControllers = [
            UIViewController(),
            UIViewController(),
            UIViewController(),
            UIViewController(),
        ]
        for vc in viewControllers {
            vc.view.backgroundColor = randomColor()
        }
        
        
        pageViewController.setViewControllers([viewControllerAtIndex(0)!], direction: .forward, animated: true, completion: nil)
        pageViewController.dataSource = self
        
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        
        pageViewController!.view.frame = view.bounds
        pageViewController.didMove(toParent: self)
        
        // Add the page view controller's gesture recognizers to the view controller's view so that the gestures are started more easily.
        view.gestureRecognizers = pageViewController.gestureRecognizers
    }
}

// MARK: - UIPageViewController DataSource and Delegate
extension YViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        var index = indexOfViewController(viewController)
        
        if (index == 0) || (index == NSNotFound) {
            return nil
        }
        
        index -= 1
        
        return viewControllerAtIndex(index)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        var index = indexOfViewController(viewController)
        
        if index == NSNotFound {
            return nil
        }
        
        index += 1
        
        if index == viewControllers.count {
            return nil
        }
        
        return viewControllerAtIndex(index)
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return viewControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
}

// MARK: - Helpers
extension YViewController {
    fileprivate func viewControllerAtIndex(_ index: Int) -> UIViewController? {
        if viewControllers.count == 0 || index >= viewControllers.count {
            return nil
        }
        return viewControllers[index]
    }
    
    fileprivate func indexOfViewController(_ viewController: UIViewController) -> Int {
        return viewControllers.index(of: viewController) ?? NSNotFound
    }
}
