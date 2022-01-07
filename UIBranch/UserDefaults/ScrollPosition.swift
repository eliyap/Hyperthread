//
//  ScrollPosition.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 7/1/22.
//

import Foundation
import CoreGraphics

/// A "bookmark" for saving scroll position.
struct TableScrollPosition: Codable, Hashable {
    let indexPath: IndexPath
    let offset: CGFloat
}

extension UserDefaults {
    var scrollPosition: TableScrollPosition? {
        get {
            guard let data = object(forKey: #function) as? Data else {
                return nil
            }
            guard let loaded = try? JSONDecoder().decode(TableScrollPosition.self, from: data) else {
                assert(false, "Could not decode TableScrollPosition!")
                return nil
            }
            return loaded
        }
        set {
            guard let encoded = try? JSONEncoder().encode(newValue) else {
                assert(false, "Could not encode!")
                return
            }
            if let newValue = newValue {
                TableLog.debug("Saved scroll position \(newValue)", print: true, true)
            }
            set(encoded, forKey: #function)
        }
    }
}

extension UserDefaults {
    /// Returns whether the operation was successful.
    @discardableResult
    func incrementScrollPositionRow() -> Bool {
        guard let val = scrollPosition else { return false }
        var path = val.indexPath
        path.row += 1
        scrollPosition = TableScrollPosition(indexPath: path, offset: val.offset)
        return true
    }
}
