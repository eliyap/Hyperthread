//
//  LoginViewController.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 7/11/21.
//

import UIKit
import Twig

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
