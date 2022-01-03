//
//  TweetCell.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 13/11/21.
//

import UIKit
import RealmSwift
import Twig

final class TweetCell: ControlledCell {
    
    public static let reuseID = "TweetCell"
    override var reuseIdentifier: String? { Self.reuseID }
    
    let depthStack = UIStackView()
    let colorMarker = ColorMarkerView()
    let depthSpacer = UIView()
    
    /// Component Views
    let stackView = UIStackView()
    let userView = UserView()
    let tweetTextView = TweetTextView()
    let albumVC = AlbumController()
    let retweetView = RetweetView()
    let metricsView = MetricsView()
    private let triangleView: TriangleView
    
    /// Variable Constraint.
    var indentConstraint: NSLayoutConstraint
    
    public static let inset: CGFloat = 8
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let triangleSize = Self.inset * 1.5
        self.triangleView = TriangleView(size: triangleSize)
        self.indentConstraint = depthSpacer.widthAnchor.constraint(equalToConstant: .zero)

        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
//        addSubview(triangleView)
//        triangleView.constrain(to: safeAreaLayoutGuide)
        
        /// Add color bar.
        depthSpacer.addSubview(colorMarker)
        colorMarker.constrain(to: depthSpacer)
        
        /// Configure Depth Stack View.
        controller.view.addSubview(depthStack)
        depthStack.axis = .horizontal
        depthStack.translatesAutoresizingMaskIntoConstraints = false
        
        /// Spacer causes "indentation" in the cell view.
        depthStack.addArrangedSubview(depthSpacer)
        NSLayoutConstraint.activate([indentConstraint])
        
        
        /// Bind to edges, with insets.
        NSLayoutConstraint.activate([
            depthStack.topAnchor.constraint(equalTo: controller.view.topAnchor, constant: Self.inset),
            depthStack.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor, constant: Self.inset),
            depthStack.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor, constant: -Self.inset),
            depthStack.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor, constant: -Self.inset),
        ])

        /// Configure Main Stack View.
        depthStack.addArrangedSubview(stackView)
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(userView)
        stackView.addArrangedSubview(tweetTextView)
        
        controller.addChild(albumVC)
        stackView.addArrangedSubview(albumVC.view)
        albumVC.didMove(toParent: controller)
        albumVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            albumVC.view.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            albumVC.view.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
        ])
        
        /// Special case: must request album be "as tall as possible".
        let atap = albumVC.view.heightAnchor.constraint(equalToConstant: .superTall)
        atap.isActive = true
        atap.priority = .defaultLow
        
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
    private let maxDepth = 14
    private let indentSize: CGFloat = 10
    public func configure(node: Node, author: User, realm: Realm) {
        userView.configure(tweet: node.tweet, user: author, timestamp: node.tweet.createdAt)
        tweetTextView.attributedText = node.tweet.fullText(context: node)
        retweetView.configure(tweet: node.tweet, realm: realm)
        metricsView.configure(node.tweet)
        albumVC.configure(tweet: node.tweet)
        
        /// Set indentation depth (minimum 1).
        let depth = min(maxDepth, node.depth)
        let indent = indentSize * CGFloat(depth)
        let newConstraint = depthSpacer.widthAnchor.constraint(equalToConstant: indent)
        replace(object: self, on: \.indentConstraint, with: newConstraint)
        
        separatorInset = UIEdgeInsets(top: 0, left: indent + indentSize, bottom: 0, right: 0)
        
        /// Use non-capped depth to determine color.
        colorMarker.configure(node: node)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
