//
//  Airport.swift
//  BranchRealm
//
//  Created by Secret Asian Man Dev on 31/10/21.
//

import Foundation
import Combine
import Twig

extension Collection {
    var isNotEmpty: Bool {
        !isEmpty
    }
}

final class Airport🆕 {
    
    /** The scheduler on which work is done.
        
        `Realm` write transactions are performed in our pipeline, which blocks other `Realm` work.
        Therefore, we must allow other threads to avoid conflict with `Airport`, by running on the same
        scheduler.
     
        Scheduler chosen based on:
        https://www.avanderlee.com/combine/runloop-main-vs-dispatchqueue-main/
     */
    public static let scheduler = DispatchQueue.main
    
    private let followUp: FollowUp = .init()
    private let newIngest: HomeIngest<TimelineNewFetcher>
    private let oldIngest: HomeIngest<TimelineOldFetcher>
    
    init() {
        self.newIngest = .init(followUp: followUp)
        self.oldIngest = .init(followUp: followUp)
    }
    
    public func requestNew() {
        newIngest.intake.send()
    }
    
    public func requestOld() {
        oldIngest.intake.send()
    }
}
