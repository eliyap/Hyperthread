//
//  MakeRealm.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 29/1/22.
//

import Foundation
import RealmSwift

/// Alias App Sematic Versions to Realm Schema Versions.
internal enum SchemaVersion: UInt64 {
    /// Launch Schema.
    case v1dot0 = 0
    
    /// No changes from `v1.0`.
    case v1dot1 = 1
    
    /// Changes:
    /// - Added video media representation
    case v1dot2 = 2
}

internal func makeRealm() -> Realm {
    let config = Realm.Configuration(schemaVersion: SchemaVersion.v1dot0.rawValue)
    return try! Realm(configuration: config)
}
