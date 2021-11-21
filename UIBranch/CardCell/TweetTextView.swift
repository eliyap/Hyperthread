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
    
    /// Reject touches that aren't tapping a URL.
    /// Source: https://stackoverflow.com/a/44878203/12395667
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        /// Obtain text offset at `point`.
        guard let pos = closestPosition(to: point) else { return false }
        guard let range = tokenizer.rangeEnclosingPosition(pos, with: .character, inDirection: .layout(.left)) else { return false }
        let startIndex = offset(from: beginningOfDocument, to: range.start)

        /// Check whether text offset has `link` attribute.
        return attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
