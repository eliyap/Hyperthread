//
//  TimeInterval.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 28/12/21.
//

import Foundation

extension TimeInterval {
    public static let minute: Self = 60
    public static let hour: Self = .minute * 60
    public static let day: Self = .hour * 24
    public static let week: Self = .day * 7
}
