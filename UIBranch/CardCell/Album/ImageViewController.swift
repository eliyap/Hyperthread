//
//  ImageViewController.swift
//  
//
//  Created by Secret Asian Man Dev on 6/12/21.
//

import UIKit
import SDWebImage

/// View model for the `Media` Realm Object.
fileprivate struct MediaModel {
    var type: MediaType.RawValue
    var url: String?
    var previewImageUrl: String?
    
    init(media: Media) {
        self.type = media.type
        self.url = media.url
        self.previewImageUrl = media.previewImageUrl
    }
}

final class ImageViewController: UIViewController {
    
    private let imageView: UIImageView = .init()
    
    private let loadingIndicator: UIActivityIndicatorView = .init()
    
    fileprivate var mediaModel: MediaModel? = nil
    
    init() {
        super.init(nibName: nil, bundle: nil)
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        /// Request that image be "as tall as possible".
        let superTall = imageView.heightAnchor.constraint(equalToConstant: .superTall)
        superTall.isActive = true
        superTall.priority = .defaultLow
        
        /// Constrain image' height and width to be within our own.
        imageView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor).isActive = true
        imageView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor).isActive = true
        
        /// Center indicator view.
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
    }
    
    func configure(media: Media) -> Void {
        mediaModel = .init(media: media)
        
        switch media.mediaType {
        case .photo:
            if let urlString = media.url {
                loadingIndicator.startAnimating()
                imageView.sd_setImage(with: URL(string: urlString)) { [weak self] (image: UIImage?, error: Error?, cacheType: SDImageCacheType, url: URL?) in
                    self?.loadingIndicator.stopAnimating()
                    if let error = error {
                        NetLog.warning("Image Loading Error \(error)")
                    }
                    if image == nil {
                        NetLog.error("Failed to load image! \(#file)")
                    }
                }
            }
        case .animated_gif:
            break
        case .video:
            break
        case .none:
            TableLog.error("Unrecognized type with value \(media.type)")
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
