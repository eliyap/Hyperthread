//
//  CountButton.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 30/1/22.
//

import UIKit

final class CountButton: UIButton {
    
    private static var config: UIButton.Configuration = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .systemGray6
        config.cornerStyle = .capsule
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
        return config
    }()
    
    @MainActor
    init() {
        super.init(frame: .zero)
        configuration = Self.config
        adjustsImageSizeForAccessibilityContentSizeCategory = true
    }
    
    /// Intercept title and style it.
    /// Replaces non-thread safe`UIConfigurationTextAttributesTransformer`.
    override func setTitle(_ title: String?, for state: UIControl.State) {
        guard let title = title else {
            return
        }

        setAttributedTitle(
            .init(string: title, attributes: [
                .foregroundColor: UIColor.label,
                .font: UIFont.preferredFont(forTextStyle: .footnote),
            ]),
            for: state
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
