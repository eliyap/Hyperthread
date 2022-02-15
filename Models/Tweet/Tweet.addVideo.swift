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
    public func addVideo(token: Realm.TransactionToken, from raw: RawV1MediaTweet) throws -> Void {
        guard let rawMedia: [RawExtendedMedia] = raw.extended_entities.map(\.media) else {
            throw MediaIngestError.missingEntities
        }
        
        for rawMediaItem in rawMedia {
            guard let videoInfo = rawMediaItem.video_info else {
                if rawMediaItem.additional_media_info == nil {
                    throw MediaIngestError.missingEntities
                } else {
                    throw MediaIngestError.advertiserMedia
                }
            }
            
            guard videoInfo.variants.isNotEmpty else {
                throw MediaIngestError.missingEntities
            }
            
            guard let mediaMatch = self.media.first(where: { mediaItem in mediaItem.id == rawMediaItem.id_str}) else {
                ModelLog.error("No matching media for raw media item with id \(rawMediaItem.id_str)")
                assert(false)
                continue
            }
            
            guard mediaMatch.mediaType == MediaType(raw: rawMediaItem.type) else {
                ModelLog.error("Mismatched media types! \(mediaMatch.mediaType!) != \(MediaType(raw: rawMediaItem.type))")
                assert(false)
                continue
            }
            
            mediaMatch.addVideo(token: token, from: videoInfo)
        }
    }
}
