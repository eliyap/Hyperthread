//
//  TimeDifference.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 13/11/21.
//

import Foundation

func approximateTimeSince(_ date: Date) -> String {
    "\(date.distance(to: Date()))"
}
