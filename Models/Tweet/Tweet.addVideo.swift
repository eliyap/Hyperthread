//
//  Tweet.addVideo.swift
//  Hyperthread
//
//  Created by Secret Asian Man Dev on 5/2/22.
//

import Foundation
import RealmSwift
import Twig

extension Tweet {
    public func addVideo(from raw: RawV1MediaTweet) throws -> Void {
        guard let rawMedia: [RawExtendedMedia] = raw.extended_entities.map(\.media) else {
            throw MediaIngestError.missingEntities
        }
        
        for rawMediaItem in rawMedia {
            guard rawMediaItem.video_info.variants.isNotEmpty else {
                throw MediaIngestError.missingEntities
            }
            
            guard let mediaMatch = self.media.first(where: { mediaItem in mediaItem.id == rawMediaItem.id_str}) else {
                ModelLog.error("No matching media for raw media item with id \(rawMediaItem.id_str)")
                assert(false)
                continue
            }
            
            mediaMatch.addVideo(from: rawMediaItem)
        }
    }
    
    
}
