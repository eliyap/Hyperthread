//
//  ViewController.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 6/11/21.
//

import UIKit
import Twig

public final class Auth: ObservableObject {
    static let shared = Auth()
    @Published var state: LoginState = .idle
    private init() {}
}

class ViewController: PMViewController {

    let table = MainTable()
    var login = LoginViewController()
    
    required init?(coder: NSCoder) {
        super.init(nibName: nil, bundle: nil)
        adopt(table)
        adopt(login)
        view.bringSubviewToFront(login.view)
        
        store(
            Auth.shared.$state
                .sink { [weak self] state in
                    if case .loggedIn = state {
                        self?.didLogIn()
                    }
                }
        )
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    fileprivate func didLogIn() -> Void {
        view.bringSubviewToFront(table.view)
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
    var authVC: AuthViewController? = nil

    init() {
        button = UIButton(configuration: .filled(), primaryAction: UIAction(handler: { [weak self] action in
            self?.startLogin()
        }))
        button.setTitle("Log in to Twitter", for: .normal)
        super.init(nibName: nil, bundle: nil)
        view.addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
//            button.widthAnchor.constraint(equalToConstant: 100),
//            button.heightAnchor.constraint(equalToConstant: 100),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    fileprivate func startLogin() -> Void {
        // TODO: show activity indicator
        Task {
            guard Auth.shared.state != LoginState.loggingIn(_) else { return }
            guard let token = await requestLogin() else { return }
            
        }
        authVC = AuthViewController(token: token, handler: callbackHandler)
    }

    required init?(coder: NSCoder) {
        fatalError("No.")
    }
    
    fileprivate func requestLogin() async -> String? {
        if let response = try? await requestToken() {
            Auth.shared.state = .loggingIn(token: response.oauth_token)
            return response.oauth_token
        } else {
            Auth.shared.state = .failed(LoginError.couldNotRequestLogin)
            return nil
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

enum LoginState {
    case idle
    case failed(Error?)
    case loggingIn(token: String)
    case loggedIn(cred: OAuthCredentials)
}

enum LoginError: Error {
    case couldNotRequestLogin
}
