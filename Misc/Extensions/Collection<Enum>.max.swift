//
//  Collection<Enum>.max.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 24/12/21.
//

import Foundation

/** Permit us to find the "maximum" enum.
    Allows us to easily determine the highest `Relevance`.
 */
extension Collection where Element: RawRepresentable, Element.RawValue: Comparable {
    func max() -> Element? {
        guard let maxRaw = map(\.rawValue).max() else { return nil }
        return .init(rawValue: maxRaw)
    }
}
