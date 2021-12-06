//
//  ImageViewController.swift
//  
//
//  Created by Secret Asian Man Dev on 6/12/21.
//

import UIKit
import SDWebImage

final class ImageViewController: UIViewController {
    
    private let imageView = UIImageView()
    
    private let test = UIView()
    
    init() {
        super.init(nibName: nil, bundle: nil)
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        /// Make image as tall as possible.
        /// Using `greatestFiniteMagnitude` triggers "NSLayoutConstraint is being configured with a constant that exceeds internal limits" warning.
        /// Instead, use a height far exceeding any screen in 2021.
        let superTall = imageView.heightAnchor.constraint(equalToConstant: 30000)
        superTall.isActive = true
        superTall.priority = .defaultLow
        
        /// Constrain image height.
        imageView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor).isActive = true
        
//        view.addSubview(test)
//        view.bringSubviewToFront(test)
//        test.backgroundColor = .red
//        test.layer.borderColor = UIColor.blue.cgColor
//        test.layer.borderWidth = 2
//        test.frame = view.bounds
    }
    
    func configure(media: Media) -> Void {
        if let urlString = media.url {
            imageView.sd_setImage(with: URL(string: urlString)) { (image: UIImage?, error: Error?, cacheType: SDImageCacheType, url: URL?) in
                if let error = error {
                    NetLog.warning("Image Loading Error \(error)")
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
//        self.view.window?.rootViewController?.view.addSubview(self.test)
//        UIView.animate(withDuration: 0.25) {
//            if let b = self.view.window?.bounds {
//                self.test.frame.origin.x = b.origin.x
//                self.test.frame.origin.y = b.origin.y
//            }
//
//        }
        
        
        
        let modal = LargeImageViewController()
        guard let root = view.window?.rootViewController else {
            assert(false, "Could not obtain root view controller!")
            return
        }
        root.present(modal, animated: true) {
            print("Done!")
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        TableLog.debug("\(Self.description()) de-initialized", print: true, false)
    }
}