//
//  UserModalView.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 29/12/21.
//

import Foundation
import UIKit

#warning("View Incomplete")
final class UserModalViewController: UIViewController {
    
    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .automatic
        view.backgroundColor = .systemRed
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
