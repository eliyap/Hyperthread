//
//  FollowUp.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 23/12/21.
//

import Foundation
import Combine
import RealmSwift

final class FollowUp {
    private let pipeline: AnyCancellable
    public let intake = PassthroughSubject<Void, Never>()
    
    init() {
        let realm = try! Realm()
        pipeline = intake
            .map { _ in
                print(realm.conversationsWithFollowUp().count)
                print(realm.discussionsWithFollowUp().count)
            }
            .sink { _ in }
    }
    
    deinit {
        pipeline.cancel()
    }
}
