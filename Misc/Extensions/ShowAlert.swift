//
//  ShowAlert.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 8/12/21.
//

import UIKit

func NOT_IMPLEMENTED() -> Void {
    showAlert(title: "Right now, this doesn't do anything", message: nil, action: "😞")
}

/// Shorthand to show the user an alert.
func showAlert(title: String? = "⚠️ Error! ⚠️", message: String?, action: String = "OK") -> Void {
    guard let scene = getWindowScene() else { return }
    guard let vc = scene.keyWindow?.rootViewController else { return }
    let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let ok = UIAlertAction(title: action, style: .default) { _ in }
    ac.addAction(ok)
    vc.present(ac, animated: true)
}
