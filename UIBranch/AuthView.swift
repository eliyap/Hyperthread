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
        if let cred = UserDefaults.groupSuite.oAuthCredentials {
            state = .loggedIn(cred: cred)
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
        return UIApplication.shared.windows.filter { $0.isKeyWindow }.first!
    }
}

