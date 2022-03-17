//
//  ImageTransition.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 15/3/22.
//

import UIKit

final class LargeImageTransitioner: UIPercentDrivenInteractiveTransition {
    
    var interactionInProgress = false

    private var shouldCompleteTransition = false
    private weak var viewController: UIViewController!

    init(viewController: UIViewController) {
        self.viewController = viewController
        super.init()
        
        /// Create gesture recognizer.
        let gesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handleGesture(_:))
        )
        viewController.view.addGestureRecognizer(gesture)
    }
    
    @objc private func handleGesture(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view!.superview!)
        let distance = sqrt(pow(translation.x, 2) + pow(translation.y, 2))
        var progress = (distance / 200)
        progress = CGFloat(fminf(fmaxf(Float(progress), 0.0), 1.0))
          
        switch gestureRecognizer.state {
            case .began:
                interactionInProgress = true
                viewController.dismiss(animated: true, completion: nil)
            
            case .changed:
                shouldCompleteTransition = progress > 0.5
                update(progress)
            
            case .cancelled:
                interactionInProgress = false
                cancel()
            
            case .ended:
                interactionInProgress = false
                if shouldCompleteTransition {
                    finish()
                } else {
                    cancel()
                }
            
            default:
                break
          }
    }
}
