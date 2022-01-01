//
//  UserTimelineWindow.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 1/1/22.
//

import Foundation
import Twig
import BlackBox

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
    
    /// When the home timeline endpoint returns, call this function to expand the global user target window.
    func expandUserTimelineWindow(tweets: [RawHydratedTweet]) -> Void {
        if let window: DateWindow = .init(tweets: tweets) {
            userTimelineWindow = userTimelineWindow.union(window)
        }
    }
}

internal extension DateWindow {
    /// Intended for use with the Home Timeline return value.
    init?(tweets: [RawHydratedTweet]) {
        guard tweets.isNotEmpty else {
            return nil
        }
        let minDate = tweets.map(\.created_at).min()!
        let maxDate = tweets.map(\.created_at).max()!
        self.init(start: minDate, end: maxDate)
    }
}

internal extension DateWindow {
    
    func overlaps(with other: DateWindow) -> Bool {
        other.end > self.start && self.end > other.start
    }
    
    func union(_ other: DateWindow) -> DateWindow {
        if overlaps(with: other) == false, other.duration > 0, self.duration > 0 {
            Logger.general.warning("No overlap between non-zero DateWindows \(self) and \(other)")
        }
        
        return .init(
            start: min(self.start, other.start),
            end: max(self.end, other.end)
        )
    }
}
