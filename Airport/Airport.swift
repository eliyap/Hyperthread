//
//  Airport.swift
//  BranchRealm
//
//  Created by Secret Asian Man Dev on 31/10/21.
//

import Foundation
import Combine
import Twig
import RealmSwift

final class Airport {
    
    /** The scheduler on which work is done.
        
        `Realm` write transactions are performed in our pipeline, which blocks other `Realm` work.
        Therefore, we must allow other threads to avoid conflict with `Airport`, by running on the same
        scheduler.
     
        Scheduler chosen based on:
        https://www.avanderlee.com/combine/runloop-main-vs-dispatchqueue-main/
     */
    public static let scheduler = DispatchQueue.main
    
    private let followUp: FollowUp
    private let newIngest: HomeIngest<TimelineNewFetcher>
    private let oldIngest: HomeIngest<TimelineOldFetcher>
    private let timelineConduit: TimelineConduit
    private let userFetcher: UserFetcher = .init()
    
    init() {
        self.followUp = .init(userFetcher: userFetcher)
        self.timelineConduit = .init(userFetcher: userFetcher)
        self.newIngest = .init(followUp: followUp, timelineConduit: timelineConduit, userFetcher: userFetcher)
        self.oldIngest = .init(followUp: followUp, timelineConduit: timelineConduit, userFetcher: userFetcher)
    }
    
    public func requestNew(onFetched completion: @escaping () -> Void) {
        newIngest.add(completion)
        newIngest.intake.send()
    }
    
    public func requestOld() {
        oldIngest.intake.send()
    }
    
    public func request(id: Tweet.ID) -> Void {
        /// Inject the ID directly.
        followUp.recycle.send([id])
    }
}

internal class UserFetcher: Conduit<User.ID, Never> {
    
    public static let shared: UserFetcher = .init()
    
    override init() {
        /// - Note: tolerance set to 100% to prevent performance hits.
        /// Docs: https://developer.apple.com/documentation/foundation/timer/1415085-tolerance
        let timer = Timer.publish(every: 0.05, tolerance: 0.05, on: .main, in: .default)
            .autoconnect()
        
        super.init()
        self.pipeline = intake
            .buffer(size: UInt(UserEndpoint.maxResults), timer)
            .filter(\.isNotEmpty)
            .asyncTryMap { (ids: [User.ID]) -> [RawUser] in
                /// Only proceed if credentials are loaded.
                guard let credentials = Auth.shared.credentials else {
                    NetLog.error("Tried to load users without credentials!")
                    assert(false)
                    return []
                }
            
                return try await users(userIDs: ids, credentials: credentials)
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    NetLog.error(error.localizedDescription)
                    assert(false)
                case .finished:
                    NetLog.error("Unexpected completion!")
                    assert(false)
                }
            }, receiveValue: { rawUsers in
                Swift.debugPrint("Received \(rawUsers.count) users")
                let realm = try! Realm()
                do {
                    try realm.writeWithToken { token in
                        for rawUser in rawUsers {
                            /// Defer to local database, otherwise assume false.
                            let isFollowing = realm.user(id: rawUser.id)?.following ?? false
                            
                            let user = User(raw: rawUser, following: isFollowing)
                            realm.add(user, update: .modified)
                        }
                    }
                } catch {
                    ModelLog.error("Failed to store users with error \(error)")
                    assert(false)
                }
            })
    }
}
