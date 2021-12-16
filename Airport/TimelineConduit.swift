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
            .flatMap { (request: Request) -> AnyPublisher in
                let publisher = PassthroughSubject<([RawHydratedTweet], [RawIncludeUser], [RawIncludeMedia]), Error>()
                Task {
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
                        Swift.debugPrint("\(tweets.count) Tweets", tweets.map(\.text))
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
