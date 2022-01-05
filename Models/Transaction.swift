//
//  Transaction.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 22/12/21.
//

import Foundation
import RealmSwift

public extension Realm {
    
    /** A token structure the existence of which guarantees we are in a Realm write transaction.
        Require this struct on methods which are only safe to perform within a write transaction.
     */
    struct TransactionToken {
        /// Allow instantiation in the function below and nowhere else.
        fileprivate init() {}
    }
    
    @discardableResult
    func writeWithToken<Result>(
        withoutNotifying tokens: [NotificationToken] = [],
        _ block: (TransactionToken) throws -> Result
    ) throws -> Result {
        try write(withoutNotifying: tokens) {
            /// Pass in a token object to demarkate that we are in a write transaction.
            try block(TransactionToken())
        }
    }
}
