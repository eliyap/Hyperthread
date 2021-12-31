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
    
    /// Track the current User ID.
    private var userID: User.ID? = nil
    
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
        
        /// Compress Twitter handle, then long username, but never the symbol!
        symbolButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        handleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        /// Configure Symbol.
        var config = UIImage.SymbolConfiguration.init(paletteColors: [.secondaryLabel])
        config = config.applying(UIImage.SymbolConfiguration(textStyle: .headline))
        symbolButton.setPreferredSymbolConfiguration(config, forImageIn: .normal)
    }

    public func configure(tweet: Tweet, user: User?, timestamp: Date) {
        self.userID = user?.id
        
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
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        /// Don't count as a cell touch.
//        super.touchesEnded(touches, with: event)
        guard let userID = userID else {
            NetLog.error("Missing User ID on username tap!")
            assert(false)
            return
        }

        line?.events.send(.usernameTouch(userID))
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
