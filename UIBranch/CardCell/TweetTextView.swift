//
//  TweetTextView.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 21/11/21.
//

import UIKit

final class TweetTextView: UITextView {
    init() {
        super.init(frame: .zero, textContainer: nil)
        
        /// Make as close as possible to `UILabel`.
        /// Source: https://kenb.us/uilabel-vs-uitextview
        isEditable = false
        isScrollEnabled = false
        backgroundColor = .clear
        contentInset = .zero
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
        layoutManager.usesFontLeading = false
        adjustsFontForContentSizeCategory = true
        isUserInteractionEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
