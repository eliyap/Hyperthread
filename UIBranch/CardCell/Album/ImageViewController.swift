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
        
        /// Constrain image height and width.
        imageView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor).isActive = true
        imageView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor).isActive = true
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
        
        /// Code stub for future big-image zoom and pan view.
        /*
        let modal = LargeImageViewController()
        guard let root = view.window?.rootViewController else {
            assert(false, "Could not obtain root view controller!")
            return
        }
        root.present(modal, animated: true) {
            print("Done!")
        }
         */
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        TableLog.debug("\(Self.description()) de-initialized", print: true, false)
    }
}
