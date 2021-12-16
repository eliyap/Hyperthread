//
//  DeferCombine.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 15/12/21.
//

import Foundation
import Combine

extension Publisher {
    /**
     Custom `Combine` operator which joins upstream values with `BufferType`'s sealed value.
     When sealed values go stale, upstream values are buffered until the sealed value is refreshed,
     then buffered values are emitted.
     
     Example printout:
     ```txt
     1 // @1s
     2 // @2s
     3 // @3s
     // value goes stale, takes 3s to refresh
     4 // @6s
     5 // @6s
     6 // @6s
     ...
     ```
     - Parameter bufferType: `DeferredBuffer` subclass with a custom `fetch` method.
     - Parameter timer: number of seconds after a fetch before a value is declate "stale".
     */
    func deferredBuffer<BufferType, BufferItem>(
        _ bufferType: BufferType.Type,
        timer: TimeInterval
    ) -> AnyPublisher<(Output, BufferItem), Failure> where
        /// Note that
        /// - `Publisher.Output == BufferType.Input`
        /// - `Publisher.Failure == BufferType.Failure`
        BufferType: DeferredBuffer<Output, BufferItem, Failure>
    {
        let subject = PassthroughSubject<(Output, BufferItem), Failure>()
        let zipper = BufferType(emitter: subject, timer: timer)
        
        let disposable: AnyCancellable = self.sink(
            receiveCompletion: { _ in
                fatalError("Should never be completed!")
            },
            receiveValue: { element in
                zipper.store(element)
            }
        )

        return subject
            .handleEvents(receiveCancel: disposable.cancel)
            .eraseToAnyPublisher()
    }
}


/**
 Enables the `deferredBuffer` operator.
 Subclass and override the `fetch` method.
 - Parameter Input: upstream publisher output type.
 - Parameter Failure: upstream publisher error type.
 */
internal class DeferredBuffer<Input, Output, Failure: Error> {
    
    /// Stores input values waiting for an output to be paired with.
    private var storage: [Input] = []
    
    /// Checks whether we are already fetching data.
    private var isFetching = false
    
    /// Where we publish downstream values.
    typealias Emitter = PassthroughSubject<(Input, Output), Failure>
    private weak var emitter: Emitter?
    
    /// Memoized output.
    private var sealed: Sealed<Output>
    
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
