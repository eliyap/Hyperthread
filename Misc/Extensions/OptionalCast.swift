//
//  OptionalCast.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 7/11/21.
//

import Foundation

/// Allow `Int64?` to be cast to and from `String?`.
public extension Optional where Wrapped == Int64 {
    init(_ string: String?) {
        if let string = string {
            self = Int64(string)
        } else {
            self = nil
        }
    }
    
    var string: String? {
        if let value = self {
            return "\(value)"
        } else {
            return nil
        }
    }
}
