//
//  UITextGranularity+CustomStringConvertible.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 28/3/22.
//

import UIKit

extension UITextGranularity: CustomStringConvertible {
    public var description: String {
        switch self {
        case .character:
            return "character"
        case .word:
            return "word"
        case .sentence:
            return "sentence"
        case .paragraph:
            return "paragraph"
        case .line:
            return "line"
        case .document:
            return "document"
        @unknown default:
            return "unknown"
        }
    }
}
