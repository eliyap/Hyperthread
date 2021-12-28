//
//  TimelineConduit.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 15/12/21.
//

import Combine
import Foundation
import Twig
import RealmSwift

final class TimelineConduit: Conduit<Void, Never> {
    
    public override init() {
        super.init()
        pipeline = intake
            .map { _ -> [Request] in
                let realm = try! Realm()
                
                /// Check up to 1 day before
                var homeWindow = DateWindow.fromHomeTimeline(in: .groupSuite) ?? .new()
                homeWindow.start.addTimeInterval(-.day)
                
                let following = realm.objects(User.self)
                    .filter(NSPredicate(format: "\(User.followingPropertyName) == YES"))
                var requests: [Request] = []
                
                /// Check what portions of the user timeline are un-fetched.
                for user in following {
                    let (a, b) = homeWindow.subtracting(user.timelineWindow)
                    if let a = a {
                        requests.append(Request(id: user.id, startTime: a.start, endTime: a.end))
                    }
                    if let b = b {
                        requests.append(Request(id: user.id, startTime: b.start, endTime: b.end))
                    }
                }
                
                return requests
            }
            .flatMap { $0.publisher }
//            .flatMap { (request: Request) -> AnyPublisher in
//                /// We place data here as it pages in asynchronously.
//                let publisher = PassthroughSubject<([RawHydratedTweet], [RawIncludeUser], [RawIncludeMedia]), Error>()
//
//                Task {
//                    /// Fetch asynchronously until there are no more pages.
//                    var nextToken: String? = nil
//                    repeat {
//                        let (tweets, users, media, token) = try await userTimeline(
//                            userID: request.id,
//                            credentials: credentials,
//                            startTime: request.startTime,
//                            endTime: request.endTime,
//                            nextToken: nextToken
//                        )
//                        publisher.send((tweets, users, media))
//                        nextToken = token
//                    } while (nextToken != nil)
//                }
//
//                return publisher.eraseToAnyPublisher()
//            }
            .sink(receiveCompletion: { (completion: Subscribers.Completion) in
                #warning("TODO")
                ///
            }, receiveValue: { request in
                print("Request \(request)")
                ///
            })
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
