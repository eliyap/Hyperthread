//
//  UserView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 13/11/21.
//

import UIKit
import RealmSwift
import Twig

final class UserView: UIStackView {
    
    private let symbolButton = UIButton()
    private let nameLabel = UILabel()
    private let handleLabel = UILabel()
    fileprivate let _spacing: CGFloat = 5

    /// Combine communication line.
    weak var line: CellEventLine? = nil
    
    init(line: CellEventLine? = nil) {
        self.line = line
        super.init(frame: .zero)
        axis = .horizontal
        alignment = .firstBaseline
        spacing = _spacing

        translatesAutoresizingMaskIntoConstraints = false
        
        addArrangedSubview(symbolButton)
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
        
        /// Configure Symbol.
        var config = UIImage.SymbolConfiguration.init(paletteColors: [.secondaryLabel])
        config = config.applying(UIImage.SymbolConfiguration(textStyle: .headline))
        symbolButton.setPreferredSymbolConfiguration(config, forImageIn: .normal)
    }

    public func configure(tweet: Tweet, user: User?, timestamp: Date) {
        if let user = user {
            nameLabel.text = user.name
            handleLabel.text = "@" + user.handle
        } else {
            TableLog.error("Received nil user!")
            nameLabel.text = "⚠️ UNKNOWN USER"
            handleLabel.text = "@⚠️"
        }
        
        switch tweet.primaryReferenceType {
        case .replied_to:
            symbolButton.isHidden = false
            symbolButton.setImage(UIImage(systemName: "arrowshape.turn.up.left.fill"), for: .normal)
        case .quoted:
            symbolButton.isHidden = false
            symbolButton.setImage(UIImage(systemName: "quote.bubble.fill"), for: .normal)
        default:
            symbolButton.isHidden = true
            
            /// Placeholder image prevents height shrinking to zero, which leads to graphical glitches.
            symbolButton.setImage(UIImage(systemName: "circle"), for: .normal)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        /// Don't count as a cell touch.
//        super.touchesEnded(touches, with: event)
        
        line?.events.send(.usernameTouch)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
