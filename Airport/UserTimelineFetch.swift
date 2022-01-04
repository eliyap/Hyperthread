//
//  UserTimelineFetch.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 4/1/22.
//

import Foundation
import RealmSwift
import Twig

func fetchFollowing() async -> Void {
    /// Check that credentials are present.
    guard let credentials = Auth.shared.credentials else {
        NetLog.error("Credentials missing.")
        assert(false)
        return
    }
    
    let followingIDs = await FollowingCache.shared.request()
    let requests: [TimelineRequest] = getRequests(followingIDs: followingIDs)
    
    /// Dispatch requests concurrently.
    /// Article: https://www.swiftbysundell.com/articles/swift-concurrency-multiple-tasks-in-parallel/
    await withTaskGroup(of: Void.self) { group in
        for request in requests {
            group.addTask {
                await execute(request, credentials: credentials, followingIDs: followingIDs)
            }
        }
    }
}

fileprivate func execute(_ request: TimelineRequest, credentials: OAuthCredentials, followingIDs: [User.ID]) async -> Void {
    let (tweets, included, users, media) = await fetchRawTimeline(request: request, credentials: credentials)
    do {
        NetLog.debug("Received \(tweets.count) user timeline tweets.", print: false, true)
        
        /// Safe to insert `included`, as we make no assumptions around `Relevance`.
        try ingestRaw(rawTweets: tweets + included, rawUsers: users, rawMedia: media, following: followingIDs)
    } catch {
        ModelLog.error("\(error)")
        assert(false, "\(error)")
    }
}

fileprivate func fetchRawTimeline(
    request: TimelineRequest,
    credentials: OAuthCredentials
) async -> RawData {
    var (tweets, included, users, media): RawData = ([], [], [], [])
    
    /// Fetch asynchronously until there are no more pages.
    var token: String? = nil
    repeat {
        do {
            let (newTweets, newIncluded, newUsers, newMedia, newToken) = try await userTimeline(
                userID: request.id,
                credentials: credentials,
                startTime: request.window.start,
                endTime: request.window.end,
                nextToken: token
            )
            
            tweets += newTweets
            included += newIncluded
            users += newUsers
            media += newMedia
            
            token = newToken
        } catch {
            NetLog.error("Timeline Request failed with error \(error)")
            assert(false)
            break
        }
    } while (token != nil)
    
    return (tweets, included, users, media)
}

fileprivate func getRequests(followingIDs: [User.ID]) -> [TimelineRequest] {
    /// Fetch complete `User` objects from Realm database.
    let realm = try! Realm()
    let users = followingIDs.compactMap(realm.user(id:))
    assert(users.count == followingIDs.count, "Users missing from realm database!")
    
    var result: [TimelineRequest] = []
    
    /// - Note: We assume that this value was updated as needed before the function call.
    let global = UserDefaults.groupSuite.userTimelineWindow
    
    /// Check what portions of the user timeline are un-fetched.
    for user in users {
        let (earlier, later) = global.subtracting(user.timelineWindow)
        if let earlier = earlier {
            result.append(TimelineRequest(id: user.id, window: earlier))
        }
        if let later = later {
            result.append(TimelineRequest(id: user.id, window: later))
        }
    }
    
    return result
}


fileprivate struct TimelineRequest {
    
    var id: User.ID
    
    var window: DateWindow
    
    init(id: User.ID, window: DateWindow) {
        self.id = id
        self.window = window
    }
}
