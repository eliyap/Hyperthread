//
//  Media.swift
//  UIBranch
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

    @Persisted
    var type: MediaType.RawValue

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
    }
}
