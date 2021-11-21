//
//  ReadStatus.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 21/11/21.
//

import UIKit

enum ReadStatus: String {
    case new = "new", read = "read", updated = "updated"
}

extension ReadStatus {
    var fillColor: CGColor {
        switch self {
        case .new:
            return UIColor.red.cgColor
        case .updated:
            return UIColor.orange.cgColor
        case .read:
            return UIColor.clear.cgColor
        }
    }
}
