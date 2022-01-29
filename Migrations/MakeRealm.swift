//
//  MakeRealm.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 29/1/22.
//

import Foundation
import RealmSwift

internal func makeRealm() -> Realm {
    let config = Realm.Configuration(schemaVersion: 0)
    return try! Realm(configuration: config)
}
