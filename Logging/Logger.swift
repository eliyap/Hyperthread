//
//  Logger.swift
//  BranchRealm
//
//  Created by Secret Asian Man Dev on 6/11/21.
//

import Foundation

class Logger {
    class var enabled: Bool { false }
    static func log(items: Any...) {
        if Self.enabled {
            Swift.debugPrint(items)
        }
    }
}

final class TableLog: Logger {
    override class var enabled: Bool { true }
}

final class NetLog: Logger {
    override class var enabled: Bool { true }
}
