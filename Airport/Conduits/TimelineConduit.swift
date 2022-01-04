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
    
    /// Conduit Object with which to request user objects.
    private weak var userFetcher: UserFetcher?
    
    public init(userFetcher: UserFetcher) {
        self.userFetcher = userFetcher
        super.init()
        pipeline = intake
            .joinFollowing()
            .map { (_, following) -> [TimelineConduit.Request] in
                return TimelineConduit.getRequests(followingIDs: following)
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
                        let (tweets, included, users, media, token) = try await userTimeline(
                            userID: request.id,
                            credentials: credentials,
                            startTime: request.startTime,
                            endTime: request.endTime,
                            nextToken: nextToken
                        )
                        publisher.send((tweets, included, users, media))
                        nextToken = token
                    } while (nextToken != nil)
                    publisher.send(completion: .finished)
                }

                return publisher.eraseToAnyPublisher()
            }
            .joinFollowing()
            .sink(receiveCompletion: { (completion: Subscribers.Completion) in
                NetLog.error("Unexpected completion: \(completion)")
                assert(false)
            }, receiveValue: { [weak self] (rawData, followingIDs) in
                let (tweets, included, users, media) = rawData
                do {
                    NetLog.debug("Received \(tweets.count) user timeline tweets.", print: false, true)
                    
                    /// Safe to insert `included`, as we make no assumptions around `Relevance`.
                    try ingestRaw(rawTweets: tweets + included, rawUsers: users, rawMedia: media, following: followingIDs)
                } catch {
                    ModelLog.error("\(error)")
                    assert(false, "\(error)")
                }
                
                /// Check the the tweets are indeed from only one `User`.
                let uniqueAuthorIDs = Set(tweets.map(\.authorID))
                if uniqueAuthorIDs.count > 1 {
                    NetLog.error("""
                        "User timeline returned multi-user blob, which should never happen!
                        - \(uniqueAuthorIDs)
                        """)
                    assert(false)
                } else if uniqueAuthorIDs.isEmpty {
                    /** Do nothing. **/
                } else {
                    let userID = uniqueAuthorIDs.first!
                    Self.updateUserWindow(userID: userID, rawTweets: tweets)
                }
                
                /// Immediately check for follow up.
                #warning("TODO")
//                    followUp.intake.send()
                
                let missingUsers = findMissingMentions(tweets: tweets, users: users)
                for userID in missingUsers {
                    self?.userFetcher?.intake.send(userID)
                }
            })
    }
    
    fileprivate static func updateUserWindow(userID: User.ID, rawTweets: [RawHydratedTweet]) -> Void {
        guard rawTweets.isNotEmpty else { return }
        
        let realm = try! Realm()
        guard let user = realm.user(id: userID) else {
            NetLog.error("Could not find user with ID \(userID)")
            assert(false)
            return
        }
        
        let blobWindow: DateWindow = .init(
            start: rawTweets.map(\.created_at).min()!,
            end: rawTweets.map(\.created_at).max()!
        )
        
        do {
            try realm.writeWithToken { token in
                user.timelineWindow = user.timelineWindow.union(blobWindow)
                ModelLog.debug("Updated Window \(user.name) \(user.timelineWindow)")
            }
        } catch {
            ModelLog.error("Failed to update user with id \(userID)")
            assert(false)
        }
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
