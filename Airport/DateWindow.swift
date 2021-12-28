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
}

extension DateWindow: Codable { }

internal extension UserDefaults {
    var userTimelineWindow: DateWindow {
        get {
            guard let data = object(forKey: #function) as? Data else {
                
            }
        }
    }
}
