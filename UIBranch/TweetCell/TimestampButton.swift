//
//  TimestampButton.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 22/12/21.
//

import Foundation
import UIKit
import Combine

final class TimestampButton: LabelledButton {
    init() {
        super.init(symbolName: "clock")
    }
    
    public func configure(_ tweet: Tweet) {
        setTitle(tweet.createdAt)
    }
    
    public func configure(_ discussion: Discussion) {
        setTitle(discussion.updatedAt)
    }
    
    public func configure(_ date: Date) {
        setTitle(date)
    }
    
    private func setTitle(_ date: Date) {
        setTitle(approximateTimeSince(date), for: .normal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
