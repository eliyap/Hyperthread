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
    var mediaType: MediaType
    
    /// Link to image asset, if `mediaType` is `.photo`.
    var url: String?
    
    /// Link for a preview frame for videos and GIFs.
    var previewImageUrl: String?
    
    /// The appended `pic.twitter.com` string, a fallback for linking out to Twitter's website for videos and GIFs.
    var picUrlString: String?
    
    init(media: Media, picUrlString: String?) {
        self.mediaType = media.mediaType
        self.url = media.url
        self.previewImageUrl = media.previewImageUrl
        self.picUrlString = picUrlString
    }
}

final class ImageViewController: UIViewController {
    
    private let imageView: UIImageView = .init()
    
    private let loadingIndicator: UIActivityIndicatorView = .init()
    
    fileprivate var mediaModel: MediaModel? = nil
    
    private let symbolView: UIImageView = .init()
    
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
        
        /// Center symbol view. 
        view.addSubview(symbolView)             
        NSLayoutConstraint.activate([
            symbolView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            symbolView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        symbolView.translatesAutoresizingMaskIntoConstraints = false
        view.bringSubviewToFront(symbolView)

        // TEMP
        
    }
    
    func configure(media: Media, picUrlString: String?) -> Void {
        mediaModel = .init(media: media, picUrlString: picUrlString)
        
        let videoSymbolConfig = UIImage.SymbolConfiguration(hierarchicalColor: .label)
            .applying(UIImage.SymbolConfiguration(textStyle: .largeTitle))
        
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
                    
                    /// Hide video symbol.
                    self?.symbolView.isHidden = true
                }
            }
        
        case .animated_gif:
            if let urlString = media.previewImageUrl {
                loadingIndicator.startAnimating()
                imageView.sd_setImage(with: URL(string: urlString)) { [weak self] (image: UIImage?, error: Error?, cacheType: SDImageCacheType, url: URL?) in
                    self?.loadingIndicator.stopAnimating()
                    if let error = error {
                        NetLog.warning("Image Loading Error \(error)")
                    }
                    if image == nil {
                        NetLog.error("Failed to load image! \(#file)")
                    }
                    
                    /// Show video symbol.
                    self?.symbolView.image = UIImage(systemName: "gift.circle", withConfiguration: videoSymbolConfig)
                    self?.symbolView.isHidden = false
                }
            }
        
        case .video:
            if let urlString = media.previewImageUrl {
                loadingIndicator.startAnimating()
                imageView.sd_setImage(with: URL(string: urlString)) { [weak self] (image: UIImage?, error: Error?, cacheType: SDImageCacheType, url: URL?) in
                    self?.loadingIndicator.stopAnimating()
                    if let error = error {
                        NetLog.warning("Image Loading Error \(error)")
                    }
                    if image == nil {
                        NetLog.error("Failed to load image! \(#file)")
                    }
                    
                    /// Show video symbol.
                    self?.symbolView.image = UIImage(systemName: "play.circle", withConfiguration: videoSymbolConfig)
                    self?.symbolView.isHidden = false
                }
            }
        case .none:
            TableLog.error("Unrecognized type with value \(media.type)")
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard let mediaModel = mediaModel else {
            TableLog.error("Missing media model!")
            assert(false)
            return
        }
        
        switch mediaModel.mediaType {
        case .photo:
            break
        case .video, .animated_gif:
            guard let urlString = mediaModel.picUrlString else {
                showAlert(message: "Sorry, we couldn't find a video URL.")
                return
            }
            guard var url = URL(string: urlString) else {
                showAlert(message: "Sorry, we couldn't open URL \n\(urlString)")
                return
            }
            
            /// Account for `https://` possibly not being prepended.
            if UIApplication.shared.canOpenURL(url) == false {
                guard let correctedUrl = URL(string: "https://" + urlString) else {
                    showAlert(message: "Sorry, we couldn't open URL \n\(urlString)")
                    return
                }
                url = correctedUrl
            }
            
            UIApplication.shared.open(url) { success in
                if success == false {
                    showAlert(message: "Sorry, we couldn't open URL \n\(urlString)")
                }
            }
        }
        
        #warning("Code Stub.")
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
