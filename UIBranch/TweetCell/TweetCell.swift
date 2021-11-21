//
//  TweetCell.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 13/11/21.
//

import UIKit
import RealmSwift
import Twig

final class TweetCell: UITableViewCell {
    
    public static let reuseID = "TweetCell"
    override var reuseIdentifier: String? { Self.reuseID }
    
    let depthStack = UIStackView()
    let colorBar = UIButton()
    let depthSpacer = UIView()
    
    /// Component Views
    let stackView = UIStackView()
    let userView = UserView()
    let tweetTextView = TweetTextView()
    let retweetView = RetweetView()
    let metricsView = MetricsView()
    // TODO: add profile image
    // TODO: add retweet marker
    private let triangleView: TriangleView
    
    private let colorBarWidth: CGFloat = 1.5
    private let inset: CGFloat = 8
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let triangleSize = self.inset * 1.5
        self.triangleView = TriangleView(size: triangleSize)
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(triangleView)
        triangleView.constrain(to: safeAreaLayoutGuide)
        
        /// Add color bar.
        depthSpacer.addSubview(colorBar)
        colorBar.translatesAutoresizingMaskIntoConstraints = false
        colorBar.layer.cornerRadius = colorBarWidth / 2
        NSLayoutConstraint.activate([
            colorBar.widthAnchor.constraint(equalToConstant: colorBarWidth),
            colorBar.trailingAnchor.constraint(equalTo: depthSpacer.trailingAnchor, constant: -inset),
            colorBar.topAnchor.constraint(equalTo: depthSpacer.topAnchor),
            colorBar.bottomAnchor.constraint(equalTo: depthSpacer.bottomAnchor),
        ])
        
        /// Configure Depth Stack View.
        contentView.addSubview(depthStack)
        depthStack.axis = .horizontal
        depthStack.translatesAutoresizingMaskIntoConstraints = false
        depthStack.addArrangedSubview(depthSpacer)
        depthStack.addArrangedSubview(stackView)
        NSLayoutConstraint.activate([
            depthStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: inset),
            depthStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            depthStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
            depthStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -inset),
        ])

        /// Configure Main Stack View.
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(userView)
        stackView.addArrangedSubview(tweetTextView)
        stackView.addArrangedSubview(retweetView)
        stackView.addArrangedSubview(metricsView)
        
        /// Manually constrain to full width.
        NSLayoutConstraint.activate([
            metricsView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            metricsView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
        ])

        backgroundColor = .flat
        
        /// Hide by default.
        triangleView.isHidden = true
    }

    /// Arbitrary number. Test Later.
    private let maxDepth = 10
    public func configure(node: Node, author: User, realm: Realm) {
        userView.configure(tweet: node.tweet, user: author, timestamp: node.tweet.createdAt)
        tweetTextView.attributedText = node.tweet.fullText()
        retweetView.configure(tweet: node.tweet, realm: realm)
        metricsView.configure(node.tweet)
        
        let depth = min(maxDepth, node.depth)
        NSLayoutConstraint.activate([
            depthSpacer.widthAnchor.constraint(equalToConstant: 10 * CGFloat(depth))
        ])
        colorBar.backgroundColor = SCColors[(depth - 1) % SCColors.count]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
