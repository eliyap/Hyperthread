//
//  ViewController.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 6/11/21.
//

import UIKit
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

public final class Auth: ObservableObject {
    static let shared = Auth()
    @Published var state: LoginState = .idle
    private init() {}
}

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
        case .loggingIn(let token):
            // TODO: show loading indicator
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

extension UIViewController {
    /// Convenience method for adding a subview to the view hierarchy.
    func adopt(_ child: UIViewController) {
        addChild(child)
        child.view.frame = view.frame
        view.addSubview(child.view)
        child.didMove(toParent: self)
    }
}

final class LoginViewController: UIViewController {

    let button: UIButton

    init() {
        button = UIButton(configuration: .filled(), primaryAction: nil)
        super.init(nibName: nil, bundle: nil)
        
        /// Configure Button.
        view.addSubview(button)
        button.setTitle("Log in to Twitter", for: .normal)
        let btnAction = UIAction(handler: { [weak self] action in
            guard Auth.shared.state.isLoggingIn == false else { return }
            self?.startLogin()
        })
        button.addAction(btnAction, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    fileprivate func startLogin() -> Void {
        Task {
            guard Auth.shared.state.isLoggingIn == false else { return }
            do {
                if let response = try await requestToken() {
                    Auth.shared.state = .loggingIn(token: response.oauth_token)
                } else {
                    Auth.shared.state = .failed(LoginError.couldNotRequestLogin)
                }
            } catch {
                Auth.shared.state = .failed(error)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("No.")
    }
}
