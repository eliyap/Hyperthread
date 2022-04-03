//
//  CGPoint.distance.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 3/4/22.
//

import CoreGraphics

extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        sqrt(pow(x-other.x, 2)+pow(y-other.y,2))
    }
}
