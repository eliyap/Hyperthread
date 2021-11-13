//
//  MetricButtons.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 13/11/21.
//

import UIKit
import Twig

final class MetricsView: UIStackView {
    let replyButton = ReplyButton()
    let retweetButton = RetweetButton()
    let likeButton = LikeButton()
    let timestampLabel = UILabel()

    fileprivate let _spacing: CGFloat = 5
    
    init() {
        super.init(frame: .zero)
        axis = .horizontal
        distribution = .fillEqually
        alignment = .center
        spacing = _spacing

        addArrangedSubview(replyButton)
        addArrangedSubview(retweetButton)
        addArrangedSubview(likeButton)
        addArrangedSubview(timestampLabel)

        timestampLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        timestampLabel.adjustsFontForContentSizeCategory = true
    }

    func configure(_ tweet: Tweet) {
        replyButton.configure(tweet)
        retweetButton.configure(tweet)
        likeButton.configure(tweet)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LabelledButton: UIButton {
    
    init(symbolName: String, symbolConfig: UIImage.SymbolConfiguration? = nil) {
        super.init(frame: .zero)
        setImage(UIImage(systemName: symbolName), for: .normal)
        var config = UIImage.SymbolConfiguration.init(paletteColors: [.secondaryLabel])
        if let other = symbolConfig {
            config = config.applying(other)
        }
        setPreferredSymbolConfiguration(config, forImageIn: .normal)
        setTitleColor(.secondaryLabel, for: .normal)
        addTarget(self, action: #selector(onTap), for: .touchUpInside)
    }
    
    @objc
    func onTap() -> Void { /* does nothing */}
    
    /// Hide metrics with 0 count.
    func setTitle(_ count: Int) -> Void {
        if count > 0 {
            setTitle("\(count)", for: .normal)
        } else {
            setTitle("", for: .normal)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class ReplyButton: LabelledButton {
    init() {
        super.init(symbolName: "arrowshape.turn.up.left.fill")
    }
    
    @objc
    override func onTap() -> Void {
        print("Reply Not Implemented!")
    }

    func configure(_ tweet: Tweet) {
        super.setTitle(tweet.metrics.reply_count)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class RetweetButton: LabelledButton {
    init() {
        super.init(symbolName: RetweetSymbol.name, symbolConfig: RetweetSymbol.config)
    }
    
    @objc
    override func onTap() -> Void {
        print("Retweet Not Implemented!")
    }

    func configure(_ tweet: Tweet) {
        super.setTitle(tweet.metrics.retweet_count)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class LikeButton: LabelledButton {
    init() {
        super.init(symbolName: "heart.fill")
    }
    
    @objc
    override func onTap() -> Void {
        print("Like Not Implemented!")
    }

    func configure(_ tweet: Tweet) {
        super.setTitle(tweet.metrics.like_count)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

