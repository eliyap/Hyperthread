//
//  MetricButtons.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 13/11/21.
//

import UIKit
import Twig

final class MetricsView: UIStackView {
    let replyButton = makeButton(symbolName: "arrowshape.turn.up.left.fill")
    let retweetButton = makeButton(symbolName: RetweetSymbol.name, symbolConfig: RetweetSymbol.config)
    let likeButton = makeButton(symbolName: "heart.fill")
    let timestampButton = makeButton(symbolName: "clock")

    fileprivate let _spacing: CGFloat = 5
    
    init() {
        super.init(frame: .zero)
        axis = .horizontal
        distribution = .fill
        alignment = .center
        spacing = _spacing
        
        translatesAutoresizingMaskIntoConstraints = false

        addArrangedSubview(replyButton)
        addArrangedSubview(retweetButton)
        addArrangedSubview(likeButton)
        addArrangedSubview(UIView())
        addArrangedSubview(timestampButton)
        
        /// Configure Action.
        likeButton.addTarget(self, action: #selector(onTapLike), for: .touchUpInside)
        replyButton.addTarget(self, action: #selector(onTapReply), for: .touchUpInside)
        retweetButton.addTarget(self, action: #selector(onTapRetweet), for: .touchUpInside)
    }

    func configure(_ tweet: Tweet) {
        setTitle(button: replyButton, count: tweet.metrics.reply_count)
        setTitle(button: retweetButton, count: tweet.metrics.retweet_count)
        setTitle(button: likeButton, count: tweet.metrics.like_count)
        timestampButton.setTitle(approximateTimeSince(tweet.createdAt), for: .normal)
    }
    
    /// Hide metrics with 0 count.
    func setTitle(button: UIButton, count: Int) -> Void {
        if count > 0 {
            button.setTitle("\(count)", for: .normal)
        } else {
            button.setTitle("", for: .normal)
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func onTapLike() -> Void {
        Swift.debugPrint("Like Not Implemented!")
    }

    @objc
    private func onTapRetweet() -> Void {
        Swift.debugPrint("Retweet Not Implemented!")
    }

    @objc
    private func onTapReply() -> Void {
        Swift.debugPrint("Reply Not Implemented!")
    }

    /// Factory Method allows us to use convenience initializer for UIButton.
    /// `configuration` initializer enables Dynamic Type in a way I couldn't figure out.
    static func makeButton(symbolName: String?, symbolConfig: UIImage.SymbolConfiguration? = nil) -> UIButton {
        var config = UIButton.Configuration.plain()
        config.buttonSize = .mini
        config.baseForegroundColor = .secondaryLabel
        let button = UIButton(configuration: config, primaryAction: nil)
        
        /// Configure Image.
        if let symbolName = symbolName {
            button.setImage(UIImage(systemName: symbolName), for: .normal)
        }
        if let symbolConfig = symbolConfig {
            button.setPreferredSymbolConfiguration(symbolConfig, forImageIn: .normal)
        }
        
        return button
    }
}
