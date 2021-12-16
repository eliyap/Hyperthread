//
//  TimelineConduit.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 15/12/21.
//

import Combine
import Foundation

final class TimelineConduit {
    
    
    public static let shared = TimelineConduit()
    
    private var pipeline: AnyCancellable? = nil
    
    private let intake = PassthroughSubject<Request, Never>()
    
    private init() {
//        pipeline = intake
//            .map {
//                
//            }
    }
    
    public func request(_ req: Request) -> Void {
        intake.send(req)
    }
}

extension TimelineConduit {
    public struct Request {
        
        var id: User.ID
        
        var startTime: Date
        
        var endTime: Date
        
        init(id: User.ID, startTime: Date, endTime: Date) {
            self.id = id
            self.startTime = startTime
            self.endTime = endTime
        }
    }
}
