//
//  LoginState.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 7/11/21.
//

import Foundation
import Twig

enum LoginState {
    case idle
    case failed(Error?)
    case loggingIn(token: String)
    case loggedIn(cred: OAuthCredentials)
    
    var isLoggingIn: Bool {
        switch self {
        case .loggingIn(token: _):
            return true
        default:
            return false
        }
    }
}

enum LoginError: Error {
    case couldNotRequestLogin
}
