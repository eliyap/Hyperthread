//
//  GeometryTargetProvider.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 18/3/22.
//

import UIKit

/// Provides a view whose frame we can target for a `matchedGeometryEffect` style transition.
protocol GeometryTargetProvider: UIView {
    var targetView: UIView { get }
}
