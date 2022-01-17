//
//  RemoveDuplicates.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 5/12/21.
//

import Foundation

/// Source: https://www.hackingwithswift.com/example-code/language/how-to-remove-duplicate-items-from-an-array
/// - Note: unlike the `Array(Set(x))` trick, this preserves ordering of elements.
extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var addedDict = [Element: Bool]()

        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }

    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
}
