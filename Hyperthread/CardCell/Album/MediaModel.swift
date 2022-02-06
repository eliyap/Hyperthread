//
//  MediaModel.swift
//  
//
//  Created by Secret Asian Man Dev on 6/2/22.
//

import Foundation

/// View model for the `Media` Realm Object.
internal struct MediaModel {
    
    enum MediaType {
        case photo
        case videoPreview
        case gifPreview
        case videoPlayer
        case gifPlayer
    }
    
    var mediaType: MediaType
    
    /// Link to image asset, if `mediaType` is `.photo`.
    var url: String?
    
    /// Link for a preview frame for videos and GIFs.
    var previewImageUrl: String?
    
    /// The appended `pic.twitter.com` string, a fallback for linking out to Twitter's website for videos and GIFs.
    var picUrlString: String?
    
    init(media: Media, picUrlString: String?) {
        self.mediaType = media.modelMediaType
        self.url = media.url
        self.previewImageUrl = media.previewImageUrl
        self.picUrlString = picUrlString
    }
}

internal extension Media {
    var modelMediaType: MediaModel.MediaType {
        switch (mediaType!, video) {
        case (.photo, _):
            return .photo
        case (.animated_gif, .none):
            return .gifPreview
        case (.animated_gif, .some):
            return .gifPlayer
        case (.video, .none):
            return .videoPreview
        case (.video, .some):
            return .videoPlayer
        }
    }
}
