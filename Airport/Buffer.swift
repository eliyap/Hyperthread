// Source: https://gist.github.com/xavierLowmiller/e9cbd460a4f8ef4cf16cfa4e181c9351
// Based on this StackOverflow answer: https://stackoverflow.com/a/61273595/4239752
import Foundation
import Combine

extension Publisher {
    /// Notes: `Output` is the output associated-type of `Publisher`, similarly `Failure` is the `Publisher`'s error type.

    /// Collects elements from the source sequence until `boundary` fires, or buffer reachers`size`.
    /// Then it emits the elements as an array and begins collecting again.
    func buffer<BoundaryPublisher: Publisher, BoundaryItem>(
        size: UInt,
        _ boundary: BoundaryPublisher
    ) -> AnyPublisher<[Output], Failure> where
        BoundaryPublisher.Output == BoundaryItem
    {
        let subject = PassthroughSubject<[Output], Failure>()

        var buffer: [Output] = []
        let lock = NSRecursiveLock()

        let boundaryDisposable: AnyCancellable = boundary.sink(
            receiveCompletion: { _ in },
            receiveValue: { _ in
                lock.lock();
                defer { lock.unlock() }
                
                /// Emit the buffer, then empty it.
                subject.send(buffer)
                buffer = []
        })

        let disposable: AnyCancellable = self.sink(
            receiveCompletion: { event in
                lock.lock();
                defer { lock.unlock() }
                
                switch event {
                case .finished:
                    /// Emit buffer contents.
                    subject.send(buffer)
                    subject.send(completion: .finished)
                
                case .failure(let error):
                    subject.send(completion: .failure(error))
                    buffer = []
                }
            },
            receiveValue: { element in
                lock.lock();
                defer { lock.unlock() }
                
                buffer.append(element)
                if buffer.count > size {
                    fatalError("Buffer should never exceed size")
                } else if buffer.count == size {
                    /// Emit the buffer, then empty it.
                    subject.send(buffer)
                    buffer = []
                }
            }
        )

        /// Combine `cancel` events.
        let completion = AnyCancellable {
            boundaryDisposable.cancel()
            disposable.cancel()
        }

        return subject
            .handleEvents(receiveCancel: completion.cancel)
            .eraseToAnyPublisher()
    }
}

extension Publisher {
    /// Notes: `Output` is the output associated-type of `Publisher`, similarly `Failure` is the `Publisher`'s error type.

    /// Collects elements from the source sequence until `boundary` emits a value, or buffer reachers`size`.
    /// Then it emits the collected elements as an array and the boundary value, and begins collecting again.
    func bufferZipper<BoundaryPublisher: Publisher, BoundaryItem>(
        size: UInt,
        _ boundary: BoundaryPublisher
    ) -> AnyPublisher<([Output], BoundaryItem), Failure> where
        BoundaryPublisher.Output == BoundaryItem
    {
        let subject = PassthroughSubject<([Output], BoundaryItem), Failure>()

        var buffer: [Output] = []
        let lock = NSRecursiveLock()

        let boundaryDisposable: AnyCancellable = boundary.sink(
            receiveCompletion: { _ in },
            receiveValue: { (boundaryValue: BoundaryItem) in
                lock.lock();
                defer { lock.unlock() }
                
                /// Emit the buffer and value, then empty the buffer.
                subject.send((buffer, boundaryValue))
                buffer = []
        })

        let disposable: AnyCancellable = self.sink(
            receiveCompletion: { _ in
                /// We do not expect this to ever complete.
                fatalError("Not designed to complete!")
            },
            receiveValue: { element in
                lock.lock();
                defer { lock.unlock() }
                
                buffer.append(element)
                
                /// Buffer count should not grow very large if the network request is fast.
                if buffer.count > 100 {
                    NetLog.warning("100 elements accumulated, possible failure?")
                }
            }
        )

        /// Combine `cancel` events.
        let completion = AnyCancellable {
            boundaryDisposable.cancel()
            disposable.cancel()
        }

        return subject
            .handleEvents(receiveCancel: completion.cancel)
            .eraseToAnyPublisher()
    }
}
