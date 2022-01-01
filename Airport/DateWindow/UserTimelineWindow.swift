//
//  UserTimelineWindow.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 1/1/22.
//

import Foundation

internal extension UserDefaults {
    /**
     Store the window of time over which we want to fetch all following User Timelines (via the v2 API).
     If no window is known, default to `.new()`, a zero width window anchored at the current `Date`.
     */
    var userTimelineWindow: DateWindow {
        get {
            guard let data = object(forKey: #function) as? Data else {
                DefaultsLog.debug("No Date Window found.", print: true, true)
                return .new()
            }
            guard let loaded = try? JSONDecoder().decode(DateWindow.self, from: data) else {
                assert(false, "Could not decode \(DateWindow.self)")
                return .new()
            }
            return loaded
        }
        set {
            guard let encoded = try? JSONEncoder().encode(newValue) else {
                assert(false, "Could not encode!")
                return
            }
            set(encoded, forKey: #function)
        }
    }
}
