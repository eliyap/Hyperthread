//
//  URLError.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 3/1/22.
//

import Foundation

/// Check if the thrown error corresponds to the device being offline.
public extension Error {
    var isOfflineError: Bool {
        let error = self as NSError
        /// Source: https://stackoverflow.com/questions/2720239/nsurlconnection-error
        return
            error.domain == NSURLErrorDomain &&
            (error.code == NSURLErrorNotConnectedToInternet || error.code == NSURLErrorDataNotAllowed)
    }
}
