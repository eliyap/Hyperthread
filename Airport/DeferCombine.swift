//
//  DeferCombine.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 15/12/21.
//

import Foundation
import Combine

class DeferCombine<Input, Output, Failure: Error> {
    
    /// Stores input values waiting for an output to be paired with.
    private var storage: [Input] = []
    
    /// Checks whether we are already fetching data.
    private var isFetching = false
    
    /// Where we publish downstream values.
    typealias Emitter = PassthroughSubject<(Input, Output), Failure>
    weak var emitter: Emitter?
    
    /// Memoized output.
    var sealed: Sealed<Output>
    
    required init(emitter: Emitter, timer: TimeInterval) {
        self.emitter = emitter
        self.sealed = Sealed<Output>(timer: timer)
    }
    
    /// - Warning: **must** be overriden.
    ///            Do not invoke superclass.
    /// Do not invoke directly!
    public func _fetch(_ onCompletion: @escaping (Output) -> Void) -> Void {
        fatalError("Use of non implemented completion handler!")
    }
    
    private func requestFetch() -> Void {
        guard isFetching == false else { return }
        isFetching = true
        defer { isFetching = false }
        
        _fetch { [weak self] output in
            /// Emit all stored values, then clear the storage.
            self?.storage.forEach { input in
                self?.emitter?.send((input, output))
            }
            self?.storage = []
            
            /// Memoize fresh value.
            self?.sealed.seal(output)
        }
    }
    
    public func store(_ input: Input) -> Void {
        if let fresh = sealed.value {
            emitter?.send((input, fresh))
        } else {
            storage.append(input)
            requestFetch()
        }
    }
}
