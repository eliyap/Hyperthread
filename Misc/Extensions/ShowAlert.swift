//
//  ShowAlert.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 8/12/21.
//

import UIKit

func NOT_IMPLEMENTED() -> Void {
    guard let scene = getWindowScene() else { return }
    guard let vc = scene.keyWindow?.rootViewController else { return }
    let ac = UIAlertController(title: "Right now, this doesn't do anything", message: nil, preferredStyle: .alert)
    let ok = UIAlertAction(title: "😞", style: .default) { _ in }
    ac.addAction(ok)
    vc.present(ac, animated: true)
}
