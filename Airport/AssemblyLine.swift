//
//  AssemblyLine.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 19/12/21.
//

import Foundation
import Combine

/**
 Pipeline for following up on Tweets.
 */
final class ThreadLine {
    /// The core of the object. Represents our data flow.
    private var pipeline: AnyCancellable? = nil
 
    
    private var intake = PassthroughSubject<Tweet.ID, Never>()
}
