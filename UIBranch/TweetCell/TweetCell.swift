//
//  TweetCell.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 13/11/21.
//

import UIKit
import RealmSwift
import Twig

final class ColorMarker: UIStackView {
    
    private let symbolButton = UIButton()
    private let bottomLine = UIButton()
    
    private let colorMarkerWidth: CGFloat = 1.5
    
    init() {
        super.init(frame: .zero)
        axis = .vertical
        alignment = .center
        
        addArrangedSubview(symbolButton)
        addArrangedSubview(bottomLine)
        
        /// Configure Symbol.
        var config = UIImage.SymbolConfiguration.init(paletteColors: [.secondaryLabel])
        config = config.applying(UIImage.SymbolConfiguration(textStyle: .footnote))
        symbolButton.setPreferredSymbolConfiguration(config, forImageIn: .normal)
        symbolButton.setImage(UIImage(systemName: "circle"), for: .normal)
    }
    
    public func constrain(to view: UIView) -> Void {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topAnchor.constraint(equalTo: view.topAnchor),
            bottomAnchor.constraint(equalTo: view.bottomAnchor),
            heightAnchor.constraint(equalTo: view.heightAnchor),
        ])
        
        bottomLine.translatesAutoresizingMaskIntoConstraints = false
        
        /// Shape the button as a vertical capsule shape.
        bottomLine.layer.cornerRadius = colorMarkerWidth / 2
        NSLayoutConstraint.activate([
            bottomLine.widthAnchor.constraint(equalToConstant: colorMarkerWidth),
        ])
        
        /// Request line be "as tall as possible".
        let superTall = bottomLine.heightAnchor.constraint(equalToConstant: .superTall)
        superTall.priority = .defaultLow
        superTall.isActive = true
        
        symbolButton.translatesAutoresizingMaskIntoConstraints = false
    }
    
    public func configure(node: Node) -> Void {
        bottomLine.backgroundColor = SCColors[(node.depth - 1) % SCColors.count]
        
        switch node.tweet.primaryReferenceType {
        
        case .replied_to:
            symbolButton.isHidden = false
            symbolButton.setImage(UIImage(systemName: ReplySymbol.name), for: .normal)
        
        case .quoted:
            symbolButton.isHidden = false
            symbolButton.setImage(UIImage(systemName: QuoteSymbol.name), for: .normal)
        
        default:
            symbolButton.isHidden = true

            /// Placeholder image prevents height shrinking to zero, which leads to graphical glitches.
            symbolButton.setImage(UIImage(systemName: "circle"), for: .normal)
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class TweetCell: ControlledCell {
    
    public static let reuseID = "TweetCell"
    override var reuseIdentifier: String? { Self.reuseID }
    
    let depthStack = UIStackView()
    let colorMarker = ColorMarker()
    let depthSpacer = UIView()
    
    /// Component Views
    let stackView = UIStackView()
    let userView = UserView()
    let tweetTextView = TweetTextView()
    let albumVC = AlbumController()
    let retweetView = RetweetView()
    let metricsView = MetricsView()
    // TODO: add profile image
    // TODO: add retweet marker
    private let triangleView: TriangleView
    
    /// Variable Constraint.
    var indentConstraint: NSLayoutConstraint
    
    public static let inset: CGFloat = 8
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let triangleSize = Self.inset * 1.5
        self.triangleView = TriangleView(size: triangleSize)
        
        /// Create inactive constraint.
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
        depthStack.addArrangedSubview(depthSpacer); NSLayoutConstraint.activate([indentConstraint])
        depthStack.addArrangedSubview(stackView)
        NSLayoutConstraint.activate([
            depthStack.topAnchor.constraint(equalTo: controller.view.topAnchor, constant: Self.inset),
            depthStack.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor, constant: Self.inset),
            depthStack.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor, constant: -Self.inset),
            depthStack.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor, constant: -Self.inset),
        ])

        /// Configure Main Stack View.
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
        
        /// Set indentation depth.
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
