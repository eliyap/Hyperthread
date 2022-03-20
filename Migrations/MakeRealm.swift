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
    
    /// No changes from `v1.2`.
    case v1dot3 = 3
}

internal func makeRealm() -> Realm {
    let config = Realm.Configuration(
        schemaVersion: SchemaVersion.v1dot2.rawValue,
        migrationBlock: { (migration: Migration, oldSchemaVersion: UInt64) in
            if oldSchemaVersion < SchemaVersion.v1dot2.rawValue {
                migration.enumerateObjects(ofType: Media.className()) { oldObject, newObject in
                    newObject![Media.videoPropertyName] = nil
                }
            }
        }
    )
    return try! Realm(configuration: config)
}
