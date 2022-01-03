//
//  URLError.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 3/1/22.
//

import Foundation

public extension Error {
    var isOfflineError: Bool {
        let error = self as NSError
        return
            error.domain == NSURLErrorDomain &&
            error.code == NSURLErrorNotConnectedToInternet
    }
}
