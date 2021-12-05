//
//  PageViewController.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 5/12/21.
//

import UIKit

class AlbumController: UIPageViewController {
    
    let source = AlbumControllerDataSource()
    
    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        delegate = source
        dataSource = source
        
        setViewControllers([source._viewControllers[0]], direction: .forward, animated: true, completion: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class AlbumControllerDataSource: NSObject, UIPageViewControllerDataSource {
    
    var _viewControllers = [
        UIViewController(),
        UIViewController(),
        UIViewController(),
        UIViewController(),
    ]
    
    override init() {
        super.init()
        for vc in _viewControllers {
            vc.view.backgroundColor = randomColor()
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = _viewControllers.firstIndex(of: viewController), index > 0 else { return nil }
        return _viewControllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = _viewControllers.firstIndex(of: viewController), index < _viewControllers.count - 1 else { return nil }
        return _viewControllers[index + 1]
    }
}

extension AlbumControllerDataSource: UIPageViewControllerDelegate {
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return _viewControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
}
