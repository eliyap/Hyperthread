//
//  PMViewController.swift
//  PencilMarkRedux
//
//  Created by Secret Asian Man Dev on 24/7/21.
//

import Foundation
import UIKit
import Combine

/// A `UIViewController` assumed to have `Combine` capabilities.
class PMViewController: UIViewController {
    
    private var observers = Set<AnyCancellable>()
    
    /// Expose private ``observers``
    public func store(_ cancellable: AnyCancellable) {
        cancellable.store(in: &observers)
    }
    
    deinit {
        /// Cancel subscriptions so that they do not leak.
        observers.forEach { $0.cancel() }
    }
}
