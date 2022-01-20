//
//  UserMessage.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 20/1/22.
//

import Foundation
import Combine

typealias UserMessageConduit = PassthroughSubject<UserMessage?, Never>

/// Represents a message that can be shown to the user, indicating progress, completion, or an error.
internal struct UserMessage {
    
    enum Category {
        case loading
        case loaded
        case offline
        case userError(UserError)
        case otherError(Error)
    }
    let category: Category
    
    /// How long the message should be displayed for.
    enum Duration {
        case indefinite
        case interval(TimeInterval)
    }
    let duration: Duration
    
    init(category: Category, duration: Duration) {
        self.category = category
        self.duration = duration
    }

    init(category: Category) {
        self.init(category: category, duration: category.defaultDuration)
    }
}

extension UserMessage.Category {
    /// Recommended time interval for each type of message.
    var defaultDuration: UserMessage.Duration{
        switch self {
        case .loading:
            return .indefinite
        case .loaded:
            return .interval(1.0)
        case .offline:
            return .interval(3.0)
        case .userError:
            return .interval(3.0)
        case .otherError:
            return .interval(3.0)
        }
    }
}
