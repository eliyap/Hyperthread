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
                    
                    /// Upon log in, also fetch following users.
                    await updateFollowing(credentials: credentials)
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
    
    private let mainVC: MainTable
    private let detailVC: DiscussionTable
    
    init() {
        self.detailVC = DiscussionTable()
        self.mainVC = MainTable(splitDelegate: detailVC)
        
        /// Set up preferred style.
        super.init(style: .doubleColumn)
        preferredDisplayMode = .oneBesideSecondary
        preferredSplitBehavior = .tile
        presentsWithGesture = false
        
        /// Make primary view wider than usual.
        /// Most discussions are just one tweet, so the primary view should be larger, as the secondary view is not always needed.
        preferredPrimaryColumnWidthFraction = 0.4
        maximumPrimaryColumnWidth = .greatestFiniteMagnitude
        
        setViewController(detailVC, for: .secondary)
        setViewController(mainVC, for: .primary)
        
        /// Monitor split events.
        delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Some class that communicates across the split view components.
protocol SplitDelegate: AnyObject {
    func present(_ discussion: Discussion) -> Void
}

extension Split: UISplitViewControllerDelegate {
    /// Prefer secondary view controller in compact width.
    /// This allows the user to keep editing the document.
    /// Docs: https://developer.apple.com/documentation/uikit/uisplitviewcontrollerdelegate/3580925-splitviewcontroller
    func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        /// Collapse to document if one is open, otherwise collapse to the document picker.
        if detailVC.discussion == nil {
            return .primary
        } else {
            return .secondary
        }
    }
}
