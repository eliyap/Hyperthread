//
//  CellEvent.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 29/12/21.
//

import Foundation
import Combine

enum CellEvent {
    case usernameTouch
}

final class CellEventLine {
    public let events: PassthroughSubject<CellEvent, Never> = .init()
    
    init() {}
}
