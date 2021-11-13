//
//  ViewController.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 6/11/21.
//

import UIKit
import Twig

class ViewController: PMViewController {

    let mainVC = Split()
    var loginVC = LoginViewController()
    var authVC: AuthViewController? = nil
    
    required init?(coder: NSCoder) {
        super.init(nibName: nil, bundle: nil)
        adopt(mainVC)
        adopt(loginVC)
        view.bringSubviewToFront(loginVC.view)
        store(Auth.shared.$state.sink(receiveValue: react))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    fileprivate func react(to state: LoginState) -> Void {
        /// Bring appropriate view to the front.
        switch state {
        case .idle:
            loginVC.view.isHidden = false
            mainVC.view.isHidden = true
        case .loggingIn(let token):
            authVC = AuthViewController(token: token, handler: callbackHandler)
            adopt(authVC!)
        case .loggedIn:
            loginVC.view.isHidden = true
            mainVC.view.isHidden = false
        default:
            break
        }
    }

    /// Handles response from `ASWebAuthenticationSession`.
    fileprivate func callbackHandler(url: URL?, error: Error?) -> Void {
        if let error = error {
            Swift.debugPrint(error.localizedDescription)
        }
        if let url = url {
            Task {
                do {
                    let credentials = try await accessToken(callbackURL: url.absoluteString)
                    Auth.shared.state = .loggedIn(cred: credentials)
                    UserDefaults.groupSuite.oAuthCredentials = credentials
                } catch {
                    Auth.shared.state = .failed(error)
                }
            }
        } else {
            Auth.shared.state = .failed(error)
        }
    }
}

final class Split: UISplitViewController {
    init() {
        /// Set up preferred style.
        super.init(style: .doubleColumn)
        preferredDisplayMode = .oneBesideSecondary
        preferredSplitBehavior = .tile
        presentsWithGesture = false
        
        let mainVC = MainTable()
        setViewController(mainVC, for: .primary)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
