//
//  DateWindow.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 28/12/21.
//

import Foundation
import RealmSwift

/** # Dev Notes – 22.01.01
 *  Entities
 *  - home date window
 *  	- the max and min dates in a home timeline fetch
 *  - global date window
 *  	- interval over which we expect all followed users to have all tweets fetched
 *  	- may be thought of as the summation of all prior home timeline fetches
 *  - user date window
 *  	- actual date window over which we have fetched this user's timeline
 * 
 *  Responding to events
 *  - home timeline fetch
 *  	- widen the global date window by forming a union with the home timeline window
 *  		- **Note**: what if the home and global windows are disjoint sets? that would suggest we missed something. I'll make it a dev crash for now
 *  	- then perform a follow up fetch
 *  - follow up fetch
 *  	- should be performed at start up
 *  	- also performed after a home timeline widening
 *  	- compare each user's window to the global window, fetch the difference
 *  - a user is newly followed
 *  	- initialize their user date window to `.new()` i.e. an empty window
 *  	- then perform a follow up fetch, this should cause them to be totally caught up to the global date window. 
 * 
 *  We can fetch deeper into the past using the user timeline endpoint than we can using the home timeline endpoint
 *
 *  we want to expand the global date window even after the home timeline window refuses to return more data.
 *
 *  We will accomplish this via the pre-fetching system: whenever a tweet is loaded, check if the global date window's `start`  is less than a day before the tweet
 *  if it is, expand the target by a day. 
 */

public struct DateWindow: Sendable {
    private var startTimeIntervalSince1970: TimeInterval
    public var start: Date {
        get {
            Date(timeIntervalSince1970: startTimeIntervalSince1970)
        }
        set {
            startTimeIntervalSince1970 = newValue.timeIntervalSince1970
        }
    }
    public var duration: TimeInterval
    public var end: Date {
        get {
            start.addingTimeInterval(duration)
        }
        set {
            precondition(newValue >= start, "End cannot be before start!")
            let newDuration = newValue.timeIntervalSince(start)
            duration = newDuration
        }
    }
    
    init(start: Date, duration: TimeInterval) {
        precondition(duration >= 0, "Duration must be non-negative!")
        self.startTimeIntervalSince1970 = start.timeIntervalSince1970
        self.duration = duration
    }
    
    init(start: Date, end: Date) {
        precondition(end >= start, "End cannot be before start!")
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
            result.earlier = DateWindow(start: self.start, end: other.start)
        }
        if other.end < self.end {
            result.later = DateWindow(start: other.end, end: self.end)
        }
        return result
    }
    
    /// The `DateWindow` capped at either end by the passed dates.
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

extension DateWindow: Codable { }

extension DateWindow {
    static func fromHomeTimeline(in store: UserDefaults) -> Self? {
        guard
            let maxID = store.maxID,
            let sinceID = store.sinceID
        else {
            DefaultsLog.debug("Could not obtain ID window", print: true, true)
            return nil
        }
        
        let realm = makeRealm()
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
