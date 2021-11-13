//
//  TimeDifference.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 13/11/21.
//

import Foundation

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
