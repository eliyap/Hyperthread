//
//  PageViewController.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 5/12/21.
//

import UIKit

class AlbumController: UIPageViewController {
    
    var _viewControllers = [
        UIViewController(),
        UIViewController(),
        UIViewController(),
        UIViewController(),
    ]
    
    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        delegate = self
        for vc in _viewControllers {
            vc.view.backgroundColor = randomColor()
        }
        
        setViewControllers([_viewControllers[0]], direction: .forward, animated: true, completion: nil)
        dataSource = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UIPageViewController DataSource and Delegate
extension AlbumController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = _viewControllers.firstIndex(of: viewController), index > 0 else { return nil }
        return _viewControllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = _viewControllers.firstIndex(of: viewController), index < _viewControllers.count - 1 else { return nil }
        return _viewControllers[index + 1]
    }
}

extension AlbumController: UIPageViewControllerDelegate {
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return _viewControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
}
