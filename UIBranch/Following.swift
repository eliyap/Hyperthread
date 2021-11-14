//
//  Following.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 13/11/21.
//

import Foundation

/// Singleton Class tracking which user's the user follows.
final class Following: ObservableObject {
    
    public static let shared = Following()
    
    @Published var ids: [User.ID]
    
    private init() {
        /// Load pre-existing IDs from UserDefaults.
        if let ids = UserDefaults.groupSuite.followingIDs {
            self.ids = ids
        } else {
            self.ids = []
        }
    }
}
