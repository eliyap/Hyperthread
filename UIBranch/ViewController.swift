//
//  ViewController.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 6/11/21.
//

import UIKit

class ViewController: UIViewController {

    let table = MainTable()
    
    required init?(coder: NSCoder) {
        super.init(nibName: nil, bundle: nil)
        adopt(table)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
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
