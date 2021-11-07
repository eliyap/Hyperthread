//
//  AsyncMap.swift
//  BranchRealm
//
//  Created by Secret Asian Man Dev on 31/10/21.
//

import Combine

/// Source: https://www.swiftbysundell.com/articles/calling-async-functions-within-a-combine-pipeline/
extension Publisher {
    func asyncMap<T>(
        _ transform: @escaping (Output) async throws -> T
    ) -> Publishers.FlatMap<Future<T, Error>,
                            Publishers.SetFailureType<Self, Error>> {
        flatMap { value in
            Future { promise in
                Task {
                    do {
                        let output = try await transform(value)
                        promise(.success(output))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
    }
}
