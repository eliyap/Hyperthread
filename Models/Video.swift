//
//  Video.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 5/2/22.
//

import Foundation
import Twig
import RealmSwift

final class VideoMedia: EmbeddedObject {
    @Persisted
    private var aspectRatioWidth: Int
    
    @Persisted
    private var aspectRatioHeight: Int
    
    public var aspectRatio: Double {
        Double(aspectRatioWidth) / Double(aspectRatioHeight)
    }
    
    @Persisted
    public var variants: List<VideoVariant>
}

final class VideoVariant: EmbeddedObject {
    @Persisted
    var bitrate: Int?
    
    @Persisted
    var contentType: VideoContentType.RawValue
    
    @Persisted
    var url: String
}

public enum VideoContentType: String {
    case video_mp4 = "video/mp4"
    case application_x_mpegURL = "application/x-mpegURL"
}
