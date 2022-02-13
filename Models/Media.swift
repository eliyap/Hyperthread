//
//  Media.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 21/11/21.
//

import Foundation
import RealmSwift
import Twig

enum MediaType: Int {
    case photo = 0
    case animated_gif = 1
    case video = 2
    
    init(raw: RawIncludeMediaType) {
        switch raw {
        case .photo:
            self = .photo
        case .animated_gif:
            self = .animated_gif
        case .video:
            self = .video
        }
    }
}

final class Media: EmbeddedObject {
    @Persisted
    var mediaKey: String
    
    /// > The media key is the ID plus a numeric prefix and an underscore.
    /// e.g.
    /// - Media ID:   `   1029825579531807971`
    /// - Media key: `13_1029825579531807971`
    /// Docs: https://developer.twitter.com/en/docs/twitter-ads-api/creatives/guides/identifying-media
    /// Derive the ID from the key.
    var id: String? {
        guard mediaKey.contains("_") else {
            ModelLog.error("Could not derive media ID from \(mediaKey)")
            assert(false)
            return nil
        }
        guard let trailing = mediaKey.split(separator: "_").last else {
            ModelLog.error("Could not derive media ID from \(mediaKey)")
            assert(false)
            return nil
        }
        return String(trailing)
    }
    
    @Persisted
    var type: MediaType.RawValue
    public var mediaType: MediaType! {
        get { .init(rawValue: type) }
        set { type = newValue.rawValue }
    }
    public static let typePropertyName = "type"

    @Persisted
    var width: Int

    @Persisted
    var height: Int

    @Persisted
    var previewImageUrl: String?

    @Persisted
    var durationMs: Int?

    @Persisted
    var altText: String?

    @Persisted
    var url: String?
    
    /// Hyperthread specific representation of video information.
    /// Handled separately because, as of 22.02.05, the v2 API does not return video URLs directly,
    /// requiring a separate call to the v1.1 API.
    @Persisted
    var video: VideoMedia?
    public static let videoPropertyName = "video"
    
    override required init() {}

    init(raw: RawIncludeMedia) {
        self.mediaKey = raw.media_key
        self.type = MediaType(raw: raw.type).rawValue
        self.width = raw.width
        self.height = raw.height
        self.previewImageUrl = raw.preview_image_url
        self.durationMs = raw.duration_ms
        self.altText = raw.alt_text
        self.url = raw.url
        self.video = nil
    }
    
    internal func addVideo(token: Realm.TransactionToken, from raw: RawVideoInfo) -> Void {
        do {
            self.video = try .init(raw: raw)
        } catch {
            ModelLog.error("Video init threw error \(error)")
            assert(false)
        }
    }
}

extension Media {
    var aspectRatio: CGFloat {
        CGFloat(height) / CGFloat(width)
    }
}
