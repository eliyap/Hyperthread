//
//  DateWindow.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 28/12/21.
//

import Foundation
import RealmSwift

public struct DateWindow {
    public var start: Date
    public var duration: TimeInterval
    public var end: Date { start.addingTimeInterval(duration) }
    
    init(start: Date, duration: TimeInterval) {
        precondition(duration >= 0, "Duration must be non-negative!")
        self.start = start
        self.duration = duration
    }
    
    init(start: Date, end: Date) {
        precondition(end >= start, "End cannot be after start!")
        self.init(start: start, duration: end.timeIntervalSince(start))
    }
    
    init(_ window: RealmDateWindow) {
        self.init(start: window.start, end: window.end)
    }
    
    public static func new() -> DateWindow {
        .init(start: Date(), duration: .zero)
    }
    
    /** The 2 possible windows formed by subtracting `other` from `self`.
        Earlier is the portion falling before `other`, later is the portion after `other`.
     */
    public func subtracting(_ other: DateWindow) -> (earlier: DateWindow?, later: DateWindow?) {
        var result: (earlier: DateWindow?, later: DateWindow?) = (nil, nil)
        if other.start > self.start {
            result.earlier = DateWindow(start: other.start, end: self.start)
        }
        if other.end < self.end {
            result.later = DateWindow(start: self.end, end: other.end)
        }
        return result
    }
    
    /// Capped at either end by the passed dates
    mutating func capped(start: Date? = nil, end: Date? = nil) -> Void {
        var s = self.start
        var e = self.end
        if let start = start {
            s = max(s, start)
        }
        if let end = end {
            e = min(e, end)
        }
        self = .init(start: s, end: e)
    }
}

internal final class RealmDateWindow: EmbeddedObject {
    @Persisted
    var start: Date
    
    @Persisted
    var end: Date
    
    init(_ window: DateWindow) {
        super.init()
        self.start = window.start
        self.end = window.end
    }
}

extension DateWindow {
    static func fromHomeTimeline(in store: UserDefaults) -> Self? {
        guard
            let maxID = store.maxID,
            let sinceID = store.sinceID
        else {
            DefaultsLog.debug("Could not obtain ID window", print: true, true)
            return nil
        }
        
        let realm = try! Realm()
        guard
            let start = realm.tweet(id: maxID)?.createdAt,
            let end = realm.tweet(id: sinceID)?.createdAt
        else {
            DefaultsLog.error("Could not find tweets in realm, should already be there!")
            assert(false)
            return .new()
        }
        
        return .init(start: start, end: end)
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
