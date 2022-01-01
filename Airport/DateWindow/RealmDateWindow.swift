//
//  RealmDateWindow.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 1/1/22.
//

import Foundation
import RealmSwift

internal final class RealmDateWindow: EmbeddedObject {
    @Persisted
    var start: Date
    
    @Persisted
    var end: Date
    
    override init() {
        super.init()
        self.start = Date()
        self.end = Date()
    }
    
    init(_ window: DateWindow) {
        super.init()
        self.start = window.start
        self.end = window.end
    }
}
