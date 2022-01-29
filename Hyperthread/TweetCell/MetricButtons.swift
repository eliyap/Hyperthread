//
//  MetricButtons.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 13/11/21.
//

import UIKit
import Twig

final class MetricsView: UIStackView {
    let replyButton = ReplyButton()
    let retweetButton = RetweetButton()
    let likeButton = LikeButton()
    let timestampButton = TimestampButton()

    fileprivate let _spacing: CGFloat = 5
    
    /// Central font settings.
    public static var font: UIFont { UIFont.preferredFont(forTextStyle: Self.fontStyle) }
    public static let fontStyle = UIFont.TextStyle.caption2
    
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
    }

    func configure(_ tweet: Tweet) {
        replyButton.configure(tweet)
        retweetButton.configure(tweet)
        likeButton.configure(tweet)
        timestampButton.configure(tweet)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class LabelledButton: UIButton {
    
    init(symbolName: String, symbolConfig: UIImage.SymbolConfiguration? = nil) {
        super.init(frame: .zero)
        
        /// Configure Image.
        setImage(UIImage(systemName: symbolName), for: .normal)
        var config = UIImage.SymbolConfiguration.init(paletteColors: [.secondaryLabel])
        config = config.applying(UIImage.SymbolConfiguration(textStyle: MetricsView.fontStyle))
        if let other = symbolConfig {
            config = config.applying(other)
        }
        setPreferredSymbolConfiguration(config, forImageIn: .normal)
        
        /// Configure Label.
        setTitleColor(.secondaryLabel, for: .normal)
        titleLabel?.font = MetricsView.font
        titleLabel?.adjustsFontForContentSizeCategory = true
        
        /// Configure Action.
        addTarget(self, action: #selector(onTap), for: .touchUpInside)
    }
    
    @objc
    func onTap() -> Void { /* does nothing */ }
    
    /// Hide metrics with 0 count.
    func setTitle(_ count: Int) -> Void {
        if count == 0 {
            setTitle("", for: .normal)
        } else if count > 1000 {
            setTitle("\(count/1000)k", for: .normal)
        } else {
            setTitle("\(count)", for: .normal)
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
        NOT_IMPLEMENTED()
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
        NOT_IMPLEMENTED()
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
        NOT_IMPLEMENTED()
    }

    func configure(_ tweet: Tweet) {
        super.setTitle(tweet.metrics.like_count)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
