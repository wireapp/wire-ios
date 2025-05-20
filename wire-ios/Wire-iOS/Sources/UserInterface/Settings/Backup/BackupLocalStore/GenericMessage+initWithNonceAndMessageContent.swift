//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation
import WireBackup
import WireDataModel
import WireProtos

extension GenericMessage {

    init?(
        nonce: UUID,
        messageContent: BackupMessageModel.Content
    ) {
        switch messageContent {

        case let .text(textContent):
            let textMessage = Text(content: textContent.text)
            self = GenericMessage(content: textMessage, nonce: nonce)

        case let .location(locationContent):
            let locationContent = Location.with { location in
                if let name = locationContent.name {
                    location.name = name
                }
                location.latitude = locationContent.latitude
                location.longitude = locationContent.longitude
                location.zoom = locationContent.zoom ?? 0
            }
            self = GenericMessage(content: locationContent, nonce: nonce)

        case let .asset(assetContent):
            var assetContent = assetContent
            switch assetContent.metadata {

            case let .image(imageData):
                let asset = Asset(
                    imageSize: CGSize(
                        width: Double(imageData.width),
                        height: Double(imageData.height)
                    ),
                    mimeType: assetContent.mimeType,
                    size: assetContent.size
                )
                // TODO: moc.zm_fileAssetCache.storeOriginalImage(data: imageData, for: message) ?
                // guard !message.isRestricted else {
                //    throw AppendMessageError.fileSharingIsRestricted
                // }
                //
                self = GenericMessage(content: asset, nonce: nonce)
            // try mergeWithExistingData(message: genericMessage) // TODO: ?

            case let .video(videoData):
                let asset = Asset.with { asset in
                    asset.original = Asset.Original.with { original in
                        original.size = assetContent.size
                        original.mimeType = assetContent.mimeType
                        original.name = assetContent.name ?? "video"
                        original.video = WireProtos.Asset.VideoMetaData.with { video in
                            video.durationInMillis = videoData.duration
                                .map { $0 / 1000 } ?? 0 // TODO: compare with backup creation
                            video.width = videoData.width ?? 0
                            video.height = videoData.height ?? 0
                        }
                    }
                }
                self = GenericMessage(content: asset, nonce: nonce)
            // TODO: contributionType = .videoMessage ?
            // TODO: moc.zm_fileAssetCache.storeOriginalFile

            case let .audio(audioData):
                let asset = Asset.with { asset in
                    asset.original = Asset.Original.with { original in
                        original.size = assetContent.size
                        original.mimeType = assetContent.mimeType
                        original.name = assetContent.name ?? "audio"
                        original.audio = Asset.AudioMetaData.with { audio in
                            let loudnessArray = audioData.normalization?.map { Float($0 / 255) }
                            audio.durationInMillis = audioData.duration.map { $0 * 1000 } ?? 0
                            // audio.normalizedLoudness = NSData(bytes: loudnessArray, length: loudnessArray.count) as
                            // Data
                            // TODO: fix
                        }
                    }
                }
                self = GenericMessage(content: asset, nonce: nonce)
            // TODO: see video

            case let .generic(data):
                if assetContent.name == nil, let name = data.name {
                    assetContent.name = name
                }
                fallthrough

            case .none:
                let asset = Asset.with { asset in
                    asset.original = Asset.Original.with { original in
                        original.size = assetContent.size
                        original.mimeType = assetContent.mimeType
                        original.name = assetContent.name ?? "file"
                    }
                }
                self = GenericMessage(content: asset, nonce: nonce)
            }
        }
    }

}
