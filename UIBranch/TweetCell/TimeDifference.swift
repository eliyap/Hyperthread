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
}

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
    let seconds = date.distance(to: Date())
    if seconds < 60 {
        return "\(Int(seconds))s"
    }
    
    let minutes = seconds / 60
    if minutes < 60 {
        return "\(Int(minutes))m"
    }

    let hours = minutes / 60
    if hours < 24 {
        return "\(Int(hours))h"
    }

    let days = hours / 24
    if days < 7 {
        return "\(Int(days))d"
    }

    let weeks = days / 7
    if days < 365 {
        return "\(Int(weeks))w"
    }

    /// - Note: Wrong! But probably close enough.
    let years = days / 365
    return "\(Int(years))y"
}
