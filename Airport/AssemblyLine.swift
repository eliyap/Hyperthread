//
//  AssemblyLine.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 19/12/21.
//

import Foundation
import Combine
import Twig
import RealmSwift

/**
 Pipeline for following up on Tweets.
 */
final class LinkLine {
    /// The core of the object. Represents our data flow.
    private var pipeline: AnyCancellable
 
    private var intake = PassthroughSubject<Void, Never>()
    
    private let credentials: OAuthCredentials
    
    init(credentials: OAuthCredentials) {
        self.credentials = credentials
        self.pipeline = intake
            .tryMap { () -> Set<Tweet.ID> in
                let toFetch = try _linkOrphans()
                return toFetch
            }
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    Swift.debugPrint(error)
                    fatalError(error.localizedDescription)
                case .finished:
                    fatalError("Should not finish")
                }
            }, receiveValue: { _ in
                /// Nothing.
            })
    }
}

/**
 An element in our Combine machinery.
 Dispenses a list of IDs you follow that is guaranteed to be recent.
 */
final class FollowingFetcher<Input, Failure: Error>
    : DeferredBuffer<Input, [User.ID], Failure>
{    
    override func _fetch(_ onCompletion: @escaping ([User.ID]) -> Void) {
        Task {
            let realm = try! await Realm()
            
            /// Assume credentials are available.
            let credentials = Auth.shared.credentials!
            
            /// If the fetch fails, fall back on local storage.
            guard let rawUsers = try? await requestFollowing(credentials: credentials) else {
                NetLog.error("Failed to fetch following list!")
                assert(false, "Failed to fetch following list!")
                
                let ids: [User.ID] = realm.objects(User.self)
                    .filter("\(User.followingPropertyName) == YES")
                    .map(\.id)
                onCompletion(ids)
            }
            
            /// Store fetched results.
            do {
                try realm.write {
                    /// Remove users who are no longer being followed.
                    realm.followingUsers()
                        .filter { user in
                            /// Find users who were marked as followed but are now missing.
                            rawUsers.contains(where: {user.id == $0.id}) == false
                        }
                        .forEach { user in
                            user.following = false
                        }
                    
                    /// Write all data, including following status, out to disk.
                    rawUsers.forEach { realm.add(User(raw: $0)) }
                }
            } catch {
                NetLog.error("Failed to store following list!")
                assert(false, "Failed to store following list!")
            }
            
            /// Call completion handler.
            onCompletion(rawUsers.map(\.id))
        }
    }
}

final class NonBranchingTweetLine {
    /// The core of the object. Represents our data flow.
    private var pipeline: AnyCancellable

    private var intake = PassthroughSubject<Tweet.ID, Never>()

    /// Controls how frequently we dispatch requests to `TweetEndpoint`.
    /// - Note: tolerance set to 100% to prevent performance hits.
    /// Docs: https://developer.apple.com/documentation/foundation/timer/1415085-tolerance
    private let timer = Timer.publish(every: 0.05, tolerance: 0.05, on: .main, in: .default)
        .autoconnect()

    private let credentials: OAuthCredentials

    private typealias RawData = ([RawHydratedTweet], [RawIncludeUser], [RawIncludeMedia])

    init(credentials: OAuthCredentials) {
        self.credentials = credentials
        self.pipeline = intake
            .buffer(size: UInt(TweetEndpoint.maxResults), timer)
            .filter(\.isNotEmpty)
            .asyncMap {
                (ids: [Tweet.ID]) -> RawData in
                NetLog.debug("Fetching \(ids.count) IDs")
                return try await hydratedTweets(
                    credentials: credentials,
                    ids: ids,
                    fields: RawHydratedTweet.fields,
                    expansions: RawHydratedTweet.expansions,
                    mediaFields: RawHydratedTweet.mediaFields
                )
            }
            .deferredBuffer(FollowingFetcher.self, timer: FollowingEndpoint.staleTimer)
            .map {
                [weak self] (rawData: RawData, ids: [User.ID]) in

                return rawData
            }

    }

}
