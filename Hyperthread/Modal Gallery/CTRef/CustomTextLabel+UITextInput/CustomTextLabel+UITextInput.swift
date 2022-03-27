//
//  CustomTextLabel+UITextInput.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 27/3/22.
//

import UIKit

/// `UITextInput` conformance for our `CustomTextLabel`
extension CustomTextLabel: UITextInput {
    /// - Note: Functions divided into files by theme, due to high complexity of protocol.
    
    var inputDelegate: UITextInputDelegate? {
        get {
            nil // TODO: implement
        }
        set(inputDelegate) {
            // TODO: implement
        }
    }
    
    var tokenizer: UITextInputTokenizer {
        return UITextInputStringTokenizer(textInput: self)
    }
    
    var hasText: Bool {
        !labelText.isEmpty
    }
}
