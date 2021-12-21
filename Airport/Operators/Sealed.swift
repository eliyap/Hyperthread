//
//  Sealed.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 15/12/21.
//

import Foundation

/** Tracks the "staleness" of a wrapped value.
    A value is "stale" if it was last fetched more than `Timer` seconds ago.
 */
final class Sealed<Wrapped> {
    
    /// Number of seconds before data is declared stale.
    public let timer: TimeInterval
    
    private var wrapped: Wrapped? = nil
    
    /// When data was last fetched.
    private var lastFetched: Date = .distantPast
    
    /// Whether the data is considered "stale", i.e. older than `Timer`.
    public var isStale: Bool {
        Date().timeIntervalSince(lastFetched) > timer
    }
    
    /// Store the passed value as the new, "fresh" value.
    public func seal(_ new: Wrapped) -> Void {
        wrapped = new
        lastFetched = Date()
    }
    
    /// The non-stale, wrapped value, if any.
    public var value: Wrapped? {
        guard isStale == false else { return nil }
        return wrapped
    }
    
    required init(initial: Wrapped? = nil, timer: TimeInterval) {
        self.timer = timer
        /// When an initial value is provided, mark it as fresh.
        if let initial = initial {
            seal(initial)
        }
    }
}
