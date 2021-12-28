//
//  DateWindow.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 28/12/21.
//

import Foundation

public struct DateWindow {
    let start: Date
    let duration: TimeInterval
    var end: Date { start.addingTimeInterval(duration) }
    
    init(start: Date, duration: TimeInterval) {
        precondition(duration >= 0, "Duration must be non-negative!")
        self.start = start
        self.duration = duration
    }
    
    init(start: Date, end: Date) {
        precondition(end >= start, "End cannot be after start!")
        self.init(start: start, duration: end.timeIntervalSince(start))
    }
    
    public static func new() -> DateWindow {
        .init(start: Date(), duration: .zero)
    }
}

extension DateWindow: Codable { }

internal extension UserDefaults {
    /**
     Store the window of time over which we have fetched *all* User Timelines (v2 API).
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
