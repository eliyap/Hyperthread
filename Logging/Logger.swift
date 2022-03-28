//
//  Logger.swift
//  BranchRealm
//
//  Created by Secret Asian Man Dev on 6/11/21.
//

import Foundation
import BlackBox

/// UITableView Logging.
let TableLog = BlackBox.Logger(name: "TableLog")

/// Networking Logging.
let NetLog = BlackBox.Logger(name: "NetLog")

/// Realm Data Model Logging.
let ModelLog = BlackBox.Logger(name: "ModelLog")
enum HTRealmError: Error {
    /// We expected some value to exist locally, and to be locatable via its ID, but it was not.
    case unexpectedNilFromID(String)
    
    /// We expected the Twitter API to turned a tuple in the form `[a, b]`, but did not receive one.
    case malformedArrayTuple
}

/// UserDefaults
let DefaultsLog = BlackBox.Logger(name: "UserDefaults")

let LiveTextLog = BlackBox.Logger(name: "LiveText")
let __LOG_LIVE_TEXT__ = true
