//
//  ViewController.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 6/11/21.
//

import UIKit
import Twig

class ViewController: PMViewController {

    let tableVC = MainTable()
    var loginVC = LoginViewController()
    var authVC: AuthViewController? = nil
    
    required init?(coder: NSCoder) {
        super.init(nibName: nil, bundle: nil)
        adopt(tableVC)
        adopt(loginVC)
        view.bringSubviewToFront(loginVC.view)
        store(Auth.shared.$state.sink(receiveValue: react))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    fileprivate func react(to state: LoginState) -> Void {
        switch state {
        case .idle:
            loginVC.view.isHidden = false
            tableVC.view.isHidden = true
        case .requestingToken:
            break
        case .loggingIn(let token):
            authVC = AuthViewController(token: token, handler: callbackHandler)
            adopt(authVC!)
        case .loggedIn:
            loginVC.view.isHidden = true
            tableVC.view.isHidden = false
        case .failed(let error):
            // TODO: show error
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

final class MainTable: UITableViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("No.")
    }
}
