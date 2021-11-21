//
//  Entities.swift
//  UIBranch
//
//  Created by Secret Asian Man Dev on 17/11/21.
//

import Foundation
import RealmSwift
import Realm
import Twig

final class Entities: EmbeddedObject {
    
    @Persisted
    var annotations: List<Annotation>
    
    @Persisted
    var hashtags: List<Tag>

    @Persisted
    var mentions: List<Mention>

    @Persisted
    var urls: List<URLEntity>

    override required init() {}
    
    init(raw: RawEntities) {
        super.init()
        raw.annotations?.map(Annotation.init(raw: )).forEach(annotations.append)
        raw.hashtags?.map(Tag.init(raw: )).forEach(hashtags.append)
        raw.mentions?.map(Mention.init(raw: )).forEach(mentions.append)
        raw.urls?.map(URLEntity.init(raw: )).forEach(urls.append)
    }
    
    /// Void differentiates this private init from the public one.
    private init(_: Void) {
        super.init()
        annotations = List<Annotation>()
        hashtags = List<Tag>()
        mentions = List<Mention>()
        urls = List<URLEntity>()
    }

    /// Represents a case with no entities.
    public static let empty = Entities()
}

final class URLEntity: EmbeddedObject {
    
    @Persisted
    var start: Int

    @Persisted
    var end: Int

    @Persisted
    var url: String

    @Persisted
    var expanded_url: String

    @Persisted
    var display_url: String

    override required init() {}

    init(raw: RawURL) {
        start = raw.start
        end = raw.end
        url = raw.url
        expanded_url = raw.expanded_url
        display_url = raw.display_url
    }
}

final class Annotation: EmbeddedObject {
    
    @Persisted
    var start: Int

    @Persisted
    var end: Int

    @Persisted
    var text: String

    @Persisted
    var probability: Double

    @Persisted
    var type: String

    override required init() {}

    init(raw: RawAnnotation) {
        start = raw.start
        end = raw.end
        text = raw.normalized_text
        probability = raw.probability
        type = raw.type
    }
}

/// Represents a Hashtag or Cashtag.
final class Tag: EmbeddedObject {
    
    @Persisted
    public var start: Int
    
    @Persisted
    public var end: Int
    
    @Persisted
    public var tag: String
    
    override required init() {}
    
    init(raw: RawTag) {
        super.init()
        start = raw.start
        end = raw.end
        tag = raw.tag
    }
}

final class Mention: EmbeddedObject {
    
    @Persisted
    public var start: Int
    
    @Persisted
    public var end: Int
    
    @Persisted
    public var id: User.ID

    @Persisted
    public var handle: String
    
    override required init() {}
    
    init(raw: RawMention) {
        start = raw.start
        end = raw.end
        id = raw.id
        handle = raw.username
    }
}
