//
//  TableWrapper.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 18/1/22.
//

import Foundation
import UIKit
import Combine
import BlackBox

final class TableWrapper: UIViewController {
    
    private let wrapped: MainTable
    private let topBar: TableTopBar
    private let loadingConduit: UserMessageConduit = .init()
    
    init(splitDelegate: SplitDelegate) {
        topBar = .init(loadingConduit: loadingConduit)
        wrapped = .init(splitDelegate: splitDelegate, loadingConduit: loadingConduit)
        super.init(nibName: nil, bundle: nil)
        adopt(wrapped)
        
        view.addSubview(topBar)
        topBar.constrain(to: view)
        view.bringSubviewToFront(topBar)
        
        #if DEBUG
        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(debugMethod)),
        ]
        #endif
    }
    
    #if DEBUG
    @objc
    func debugMethod() {
        // loading method
//        loadingConduit.send(.init(category: .loading, duration: .interval(1.0)))
        
        // present alert controller
        let alertController = requestURL(completion: { (string: String?) in
            guard let string = string else {
                return
            }
            #warning("handle errors")
            try! TableWrapper.request(string: string)
        })
        self.present(alertController, animated: true, completion: nil)
    }
    #endif
    
    static func request(string: String) throws -> Void {
        let tweetID: String
        if string.contains("/") {
            guard let trailing = string.split(separator: "/").last else {
                Logger.general.error("Could not get last component in '\(string)'")
                assert(false)
                
                throw TweetLookupError.badString
            }
            tweetID = String(trailing)
        } else {
            tweetID = string
        }
        
        let isDecimcalDigits = CharacterSet(charactersIn: tweetID).isSubset(of: CharacterSet.decimalDigits)
        guard isDecimcalDigits else {
            throw TweetLookupError.badString
        }
        
        #warning("lookup tweet here")
    }
    
    required init?(coder: NSCoder) {
        fatalError("No.")
    }
}

enum TweetLookupError: Error {
    case badString
    case couldNotFindTweet
}
