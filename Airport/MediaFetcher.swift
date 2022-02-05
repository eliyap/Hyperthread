//
//  MediaFetcher.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 5/2/22.
//

import Foundation
import Combine
import Twig

final class MediaFetcher {
    /// Set tolerance to 100% to avoid performance issues.
    private let timer = Timer.publish(every: StatusesEndpoint.interval, tolerance: StatusesEndpoint.interval, on: .main, in: .default)
        .autoconnect()
    
    private var observers: Set<AnyCancellable> = []
    
    private let unfetched = makeRealm()
        .objects(Tweet.self)
        .filter(NSPredicate(format: """
            SUBQUERY(\(Tweet.mediaPropertyName), $m,
                $m.\(Media.typePropertyName) == \(MediaType.animated_gif.rawValue)
             OR $m.\(Media.typePropertyName) == \(MediaType.video.rawValue)
            ).@count > 0
            """))
    
    public static let shared: MediaFetcher = .init()
    private init() {
        let observer = timer.sink { [weak self] _ in
            let c = self?.unfetched.count
            print("Counted \(c)")
        }
        observer.store(in: &observers)
    }
    
    deinit {
        for observer in observers {
            observer.cancel()
        }
    }
}
