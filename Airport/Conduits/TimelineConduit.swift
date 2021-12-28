//
//  TimelineConduit.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 15/12/21.
//

import Combine
import Foundation
import Twig

final class TimelineConduit: Conduit<TimelineConduit.Request, Never> {
    
    public init(credentials: OAuthCredentials) {
        super.init()
        pipeline = intake
            .flatMap { (request: Request) -> AnyPublisher in
                /// We place data here as it pages in asynchronously.
                let publisher = PassthroughSubject<([RawHydratedTweet], [RawIncludeUser], [RawIncludeMedia]), Error>()
                
                Task {
                    /// Fetch asynchronously until there are no more pages.
                    var nextToken: String? = nil
                    repeat {
                        let (tweets, users, media, token) = try await userTimeline(
                            userID: request.id,
                            credentials: credentials,
                            startTime: request.startTime,
                            endTime: request.endTime,
                            nextToken: nextToken
                        )
                        publisher.send((tweets, users, media))
                        nextToken = token
                    } while (nextToken != nil)
                }
                
                return publisher.eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { (completion: Subscribers.Completion<Error>) in
                ///
            }, receiveValue: { ([RawHydratedTweet], [RawIncludeUser], [RawIncludeMedia]) in
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
