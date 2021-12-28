//
//  Conduit.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 28/12/21.
//

import Foundation
import Combine

/// An object wrapping a Combine data processing "pipeline".
/// Takes care of the oft-forgotten step of cancelling the `AnyCancellable`.
public class Conduit<Input, Failure: Error> {
    public var pipeline: AnyCancellable? = nil
    public let intake: PassthroughSubject<Input, Failure> = .init()
    public init() {}
    deinit {
        pipeline?.cancel()
        pipeline = nil
    }
}
