//
//  TimeDifference.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 13/11/21.
//

import Foundation

enum Elapsed {
    case seconds(Int)
    case minutes(Int)
    case hours(Int)
    case days(Int)
    case weeks(Int)
    case years(Int)
    
    init(since date: Date) {
        let seconds = date.distance(to: Date())
        if seconds < 60 {
            self = .seconds(Int(seconds))
            return
        }
        
        let minutes = seconds / 60
        if minutes < 60 {
            self = .minutes(Int(minutes))
            return
        }

        let hours = minutes / 60
        if hours < 24 {
            self = .hours(Int(hours))
            return
        }

        let days = hours / 24
        if days < 7 {
            self = .days(Int(days))
            return
        }

        let weeks = days / 7
        if days < 365 {
            self = .weeks(Int(weeks))
            return
        }

        /// - Note: Wrong! But probably close enough.
        let years = days / 365
        self = .years(Int(years))
    }
}

extension Elapsed: CustomStringConvertible {
    var description: String {
        switch self {
        case .seconds(let seconds):
            return "\(seconds)s"
        case .minutes(let minutes):
            return "\(minutes)m"
        case .hours(let hours):
            return "\(hours)h"
        case .days(let days):
            return "\(days)d"
        case .weeks(let weeks):
            return "\(weeks)w"
        case .years(let years):
            return "\(years)y"
        }
    }
}

extension Elapsed: Equatable { }

func approximateTimeSince(_ date: Date) -> Elapsed {
    let seconds = date.distance(to: Date())
    if seconds < 60 {
        return .seconds(Int(seconds))
    }
    
    let minutes = seconds / 60
    if minutes < 60 {
        return .minutes(Int(minutes))
    }

    let hours = minutes / 60
    if hours < 24 {
        return .hours(Int(hours))
    }

    let days = hours / 24
    if days < 7 {
        return .days(Int(days))
    }

    let weeks = days / 7
    if days < 365 {
        return .weeks(Int(weeks))
    }

    /// - Note: Wrong! But probably close enough.
    let years = days / 365
    return .years(Int(years))
}

/// A very rough method of creating a teeny timestamp.
func approximateTimeSince(_ date: Date) -> String {
    let interval: Elapsed = approximateTimeSince(date)
    return interval.description
}
