//
//  AuthView.swift
//  Branch
//
//  Created by Secret Asian Man Dev on 16/10/21.
//

import AuthenticationServices
import UIKit
import Twig
import SwiftUI

/// Singleton Authorization Object.
public final class Auth: ObservableObject {
    static let shared = Auth()
    @Published var state: LoginState = .idle
    private init() {
        /// Load pre-existing credentials from UserDefaults.
        if let cred = UserDefaults.groupSuite.oAuthCredentials {
            state = .loggedIn(cred: cred)
        }
    }
    
    public var credentials: OAuthCredentials? {
        switch state {
        case .loggedIn(let cred):
            return cred
        default:
            return nil
        }
    }
}

final class AuthViewController: UIViewController {
    
    var session: ASWebAuthenticationSession? = nil
    
    init(token: String, handler: @escaping ASWebAuthenticationSession.CompletionHandler) {
        super.init(nibName: nil, bundle: nil)
        view = UIActivityIndicatorView()
        self.session = session(token: token, handler: handler)
        session?.start()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    func session(token: String, handler: @escaping ASWebAuthenticationSession.CompletionHandler) -> ASWebAuthenticationSession {
        let session = ASWebAuthenticationSession(
            url: URL(string: "https://api.twitter.com/oauth/authorize?oauth_token=\(token)")!,
            callbackURLScheme: Twig.scheme,
            completionHandler: handler
        )
        session.presentationContextProvider = self
        return session
    }
}

extension AuthViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        /// Source: https://stackoverflow.com/a/68989580/12395667
        let window = UIApplication.shared.connectedScenes
            /// Keep only active scenes, onscreen and visible to the user
            .filter { $0.activationState == .foregroundActive }
            /// Keep only the first `UIWindowScene`
            .first(where: { $0 is UIWindowScene })
            /// Get its associated windows
            .flatMap({ $0 as? UIWindowScene })?.windows
            /// Finally, keep only the key window
            .first(where: \.isKeyWindow)
        
        /// Blindly hope that this works.
        return window!
    }
}

