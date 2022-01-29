//
//  FirstFetch.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 16/1/22.
//

import Foundation

extension UserDefaults {
    /// Records whether a fetch was already run on this device.
    var firstFetch: Bool {
        get {
            /// `object(forKey: )` checks existence, if value is not set, assume true.
            /// Source: https://cocoacasts.com/ud-7-how-to-check-if-a-value-exists-in-user-defaults-in-swift
            if object(forKey: #function) != nil {
                return bool(forKey: #function)
            } else {
                return true
            }
        }
        set {
            set(newValue, forKey: #function)
        }
    }
}
