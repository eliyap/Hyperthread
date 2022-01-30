//
//  TweetTextView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 21/11/21.
//

import UIKit

final class TweetTextView: UITextView {
    @MainActor
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
        let hasLinkAttribute = attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
        if hasLinkAttribute {
            /**
             When trailing URLs wrap across lines, they leave a "ghost region".
             Points in the ghost region have no text, but the `closestPosition` will be at the URL.
             
             Example (ghost region marked `X`)
             ```
             blah blah blah blah
             blah blah www.example
             .com/home XXXXXXXXXXX
             ```
             
             Touches in the ghost region do not count as URL taps.
             Since we only want to return URL taps, require taps fall within some threshhold of the identified closest character.
             Threshhold determined experimentally.
             */
            let distanceThreshhold: CGFloat = 20
            
            let textCenter = firstRect(for: range).center
            let distance = textCenter.distance(to: point)
            return distance < distanceThreshhold
        } else {
            return false
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate extension CGRect {
    var center: CGPoint {
        var pt = origin
        pt.x += height / 2
        pt.y += width / 2
        return pt
    }
}

fileprivate extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        sqrt(pow(x-other.x, 2)+pow(y-other.y,2))
    }
}
