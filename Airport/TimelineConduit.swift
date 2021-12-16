//
//  TimelineConduit.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 15/12/21.
//

import Combine
import Foundation
import Twig

final class TimelineConduit {
    
    
    private var pipeline: AnyCancellable? = nil
    
    private let intake = PassthroughSubject<Request, Never>()
    
    public init(credentials: OAuthCredentials) {
        pipeline = intake
            .flatMap {
                userTimelinePublisher(userID: $0.id, credentials: credentials, startTime: $0.startTime, endTime: $0.endTime)
            }
            .sink(receiveCompletion: { (completion: Subscribers.Completion<URLError>) in
                ///
            }, receiveValue: { (data: Data) in
                ///
            })
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
