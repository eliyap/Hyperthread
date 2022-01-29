//
//  TimestampButton.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 22/12/21.
//

import Foundation
import UIKit
import Combine

fileprivate final class TimestampTicker {
    
    public static let shared = TimestampTicker()
    
    private init() {}
    
    /// - Note: tolerance set to 100% to prevent performance hits.
    /// Docs: https://developer.apple.com/documentation/foundation/timer/1415085-tolerance
    public let timer = Timer.publish(every: 1, tolerance: 1, on: .main, in: .default)
        .autoconnect()
}

internal final class TimestampButton: LabelledButton {
    
    private var subscription: AnyCancellable? = nil
    private var elapsed: Elapsed = .seconds(0)
    
    init() {
        super.init(symbolName: "clock")
    }
    
    public func configure(_ tweet: Tweet) {
        autoUpdateWith(tweet.createdAt)
    }
    
    public func configure(_ discussion: Discussion) {
        autoUpdateWith(discussion.updatedAt)
    }
    
    public func configure(_ date: Date) {
        autoUpdateWith(date)
    }
    
    public func autoUpdateWith(_ date: Date) {
        subscribe(date)
        update(with: date)
    }
    
    private func subscribe(_ date: Date) -> Void {
        /// Cancel old subscription first to prevent memory leak.
        subscription?.cancel()
        subscription = TimestampTicker.shared.timer
            /// We don't actually need the date, just the 1Hz notification.
            .map { _ in return Void() }
            /// Check if the label will change. If not, ignore it.
            .filter { [weak self] in
                Elapsed(since: date) != self?.elapsed
            }
            .sink { [weak self] in
                self?.update(with: date)
            }
    }
    
    private func update(with date: Date) {
        elapsed = Elapsed(since: date)
        setTitle(elapsed.description, for: .normal)
    }
    
    deinit {
        subscription?.cancel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
