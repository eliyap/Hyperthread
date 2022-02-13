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
    
    override required init() {}
    
    public init(raw: RawVideoInfo) throws {
        super.init()
        guard raw.aspect_ratio.count == 2 else {
            throw HTRealmError.malformedArrayTuple
        }
        
        self.aspectRatioWidth = raw.aspect_ratio[0]
        self.aspectRatioHeight = raw.aspect_ratio[1]
        
        self.variants = .init()
        for rawVariant in raw.variants {
            self.variants.append(VideoVariant(raw: rawVariant))
        }
    }
}

final class VideoVariant: EmbeddedObject {
    @Persisted
    var bitrate: Int?
    
    @Persisted
    private var _contentType: VideoContentType.RawValue
    public var contentType: VideoContentType! {
        get { .init(rawValue: _contentType) }
        set { _contentType = newValue.rawValue }
    }
    
    @Persisted
    var url: String
    
    override required init() {}
    
    public init(raw: RawMediaVariant) {
        super.init()
        self.bitrate = raw.bitrate
        self._contentType = raw.content_type.rawValue
        self.url = raw.url
    }
}

public enum VideoContentType: String {
    case video_mp4 = "video/mp4"
    case application_x_mpegURL = "application/x-mpegURL"
}
