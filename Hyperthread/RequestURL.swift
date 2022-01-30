//
//  RequestURL.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 29/1/22.
//

import UIKit
import BlackBox

func requestURL(completion: @escaping (String?) -> ()) -> UIAlertController {
    let alert = UIAlertController(title: "Lookup Tweet", message: "Twitter URL", preferredStyle: .alert)
    alert.addTextField { (textField) in
        textField.placeholder = "https://twitter.com/s/status/1485402219092398081"
        textField.text = ""
    }
    
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
        completion(nil)
    }))
    
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] _ in
        guard let alert = alert else {
            Logger.general.error("nil weak value in \(#function)")
            assert(false)
            
            completion(nil)
            return
        }
        guard let textField = alert.textFields?.first else {
            Logger.general.error("Failed to find text field!")
            assert(false)
            
            completion(nil)
            return
        }
        completion(textField.text)
    }))
    
    return alert
}
