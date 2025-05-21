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
        messageContent: MessageBackupModel.Content
    ) {
        switch messageContent {

        case let .text(textContent):
            self = GenericMessage(content: Text(textContent), nonce: nonce)

        case let .location(locationContent):
            self = GenericMessage(content: Location(locationContent), nonce: nonce)

        case let .asset(assetContent):
            self = GenericMessage(content: Asset(assetContent), nonce: nonce)

        }
    }

}

// MARK: -

extension Text {

    fileprivate init(_ textContent: MessageBackupModel.Content.TextContent) {
        self.init(content: textContent.text)
    }

}

extension Location {

    fileprivate init(_ locationContent: MessageBackupModel.Content.LocationContent) {
        self = .with { location in
            if let name = locationContent.name {
                location.name = name
            }
            location.latitude = locationContent.latitude
            location.longitude = locationContent.longitude
            location.zoom = locationContent.zoom ?? 0
        }
    }

}

extension Asset {

    fileprivate init(_ assetContent: MessageBackupModel.Content.AssetContent) {
        self = .with { asset in
            asset.original.mimeType = assetContent.mimeType
            asset.original.size = assetContent.size
            if let name = assetContent.name, !name.isEmpty {
                asset.original.name = name
            }
            asset.uploaded = Asset.RemoteData(
                otrKey: assetContent.otrKey,
                sha256: assetContent.sha256
            )
            asset.uploaded.assetID = assetContent.assetID
            if let assetToken = assetContent.assetToken, !assetToken.isEmpty {
                asset.uploaded.assetToken = assetToken
            }
            if let assetDomain = assetContent.assetDomain, !assetDomain.isEmpty {
                asset.uploaded.assetDomain = assetDomain
            }
            if let encryption = assetContent.encryption {
                asset.uploaded.encryption = EncryptionAlgorithm(encryption)
            }
            if let metadata = assetContent.metadata {
                asset.original.metaData = Asset.Original.OneOf_MetaData(metadata)
                if !asset.original.hasName, let name = fallbackName(for: metadata) {
                    asset.original.name = name
                }
            }
        }
    }

}

extension EncryptionAlgorithm {

    fileprivate init(_ encryption: MessageBackupModel.Content.AssetContent.EncryptionAlgorithm) {
        switch encryption {
        case .aesCBC:
            self = .aesCbc
        case .aesGCM:
            self = .aesGcm
        }
    }

}

extension Asset.Original.OneOf_MetaData {

    fileprivate init(_ metadata: MessageBackupModel.Content.AssetContent.Metadata) {
        switch metadata {

        case let .image(imageMetadata):
            self = .image(Asset.ImageMetaData.with { image in
                image.width = imageMetadata.width
                image.height = imageMetadata.height
                if let tag = imageMetadata.tag, !tag.isEmpty {
                    image.tag = tag
                }
            })

        case let .video(videoMetadata):
            fatalError()

        case let .audio(audioMetadata):
            fatalError()

        case let .generic(genericMetadata):
            fatalError()

        }
    }

}

/*

        switch assetContent.metadata {

        case let .video(videoData):
            asset = Asset.with { asset in
                asset.original = Asset.Original.with { original in
                    original.size = assetContent.size
                    original.mimeType = assetContent.mimeType
                    original.name = assetContent.name ?? "video"
                    original.video = WireProtos.Asset.VideoMetaData.with { video in
                        video.durationInMillis = videoData.duration.map { $0 / 1000 } ?? 0 // TODO: compare with backup creation
                        video.width = videoData.width ?? 0
                        video.height = videoData.height ?? 0
                    }
                }
            }

        case let .audio(audioData):
            asset = Asset.with { asset in
                asset.original = Asset.Original.with { original in
                    original.size = assetContent.size
                    original.mimeType = assetContent.mimeType
                    original.name = assetContent.name ?? "audio"
                    original.audio = Asset.AudioMetaData.with { audio in
                        let loudnessArray = audioData.normalization?.map { Float($0 / 255) }
                        audio.durationInMillis = audioData.duration.map { $0 * 1000 } ?? 0
                        // audio.normalizedLoudness = NSData(bytes: loudnessArray, length: loudnessArray.count) as Data
                        // TODO: fix
                    }
                }
            }

        case let .generic(data):
            // TODO: asset =
            var assetContent = assetContent
            if assetContent.name == nil, let name = data.name {
                assetContent.name = name
            }
            fallthrough

        case .none:
            asset = Asset.with { asset in
                asset.original = Asset.Original.with { original in
                    original.size = assetContent.size
                    original.mimeType = assetContent.mimeType
                    original.name = assetContent.name ?? "file"
                }
            }
        }
*/

private func fallbackName(for metadata: MessageBackupModel.Content.AssetContent.Metadata) -> String? {
    switch metadata {

    case .image:
        "image"

    case .video:
        "video"

    case .audio:
        "audio"

    case .generic(let genericMetadata):
        if let name = genericMetadata.name, !name.isEmpty {
            name
        } else {
            "file"
        }

    }
}
