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
            .deferredBuffer(FollowingFetcher.self, timer: FollowingEndpoint.staleTimer)
            .map { (_, following) -> [TimelineConduit.Request] in
                /// Add an extra day to the start of the home timeline window.
                var homeWindow = DateWindow.fromHomeTimeline(in: .groupSuite) ?? .new()
                homeWindow.start.addTimeInterval(-.day)
                homeWindow.duration += .day
                
                Swift.debugPrint("Home Window \(homeWindow)")
                
                /// The periods of time for which we need to fetch tweets for each user.
                var requests: [Request] = []
                
                /// Fetch complete `User` objects from Realm database.
                let realm = try! Realm()
                let users = following.compactMap(realm.user(id:))
                assert(users.count == following.count, "Users missing from realm database!")
                
                /// Check what portions of the user timeline are un-fetched.
                for user in users {
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
            /// Transform array into a stream of `Request`s.
            .flatMap { $0.publisher }
            /// Perform a paginated fetch for each `Request`.
            .flatMap { (request: Request) -> AnyPublisher<RawData, Error> in
                /// Check that credentials are present.
                guard let credentials = Auth.shared.credentials else {
                    NetLog.error("Credentials missing.")
                    assert(false)
                    return Just(([], [], [], []))
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                
                /// We place data here as it pages in asynchronously.
                let publisher = PassthroughSubject<RawData, Error>()

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
                        publisher.send((tweets, [], users, media))
                        nextToken = token
                    } while (nextToken != nil)
                }

                return publisher.eraseToAnyPublisher()
            }
            .deferredBuffer(FollowingFetcher.self, timer: FollowingEndpoint.staleTimer)
            .sink(receiveCompletion: { (completion: Subscribers.Completion) in
                NetLog.error("Unexpected completion: \(completion)")
                assert(false)
            }, receiveValue: { (rawData, followingIDs) in
                let (tweets, _, users, media) = rawData
                do {
                    NetLog.debug("Received \(tweets.count) user timeline tweets.", print: true, true)
                    try ingestRaw(rawTweets: tweets, rawUsers: users, rawMedia: media, following: followingIDs)
                    
                    /// Immediately check for follow up.
                    #warning("TODO")
//                    followUp.intake.send()
                } catch {
                    ModelLog.error("\(error)")
                    assert(false, "\(error)")
                }
            })
    }
    
    fileprivate static func getRequests(followingIDs: [User.ID]) -> [TimelineConduit.Request] {
        /// Fetch complete `User` objects from Realm database.
        let realm = try! Realm()
        let users = followingIDs.compactMap(realm.user(id:))
        assert(users.count == followingIDs.count, "Users missing from realm database!")
        
        var result: [TimelineConduit.Request] = []
        
        /// - Note: We assume that this value was updated as needed before the function call.
        let global = UserDefaults.groupSuite.userTimelineWindow
        
        /// Check what portions of the user timeline are un-fetched.
        for user in users {
            let (earlier, later) = global.subtracting(user.timelineWindow)
            if let earlier = earlier {
                result.append(Request(id: user.id, startTime: earlier.start, endTime: earlier.end))
            }
            if let later = later {
                result.append(Request(id: user.id, startTime: later.start, endTime: later.end))
            }
        }
        
        return result
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
