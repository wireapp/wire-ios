//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import GenericMessageProtocol
import WireBackup
import WireDataModel

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

private extension Text {

    init(_ textContent: MessageBackupModel.Content.TextContent) {
        self.init(content: textContent.text)
    }

}

private extension Location {

    init(_ locationContent: MessageBackupModel.Content.LocationContent) {
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

private extension Asset {

    init(_ assetContent: MessageBackupModel.Content.AssetContent) {
        self = .with { asset in
            asset.original.mimeType = assetContent.mimeType
            asset.original.size = assetContent.size
            if let name = assetContent.name, !name.isEmpty {
                asset.original.name = name
            }
            asset.uploaded = Asset.RemoteData(
                withOTRKey: assetContent.otrKey,
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

private extension EncryptionAlgorithm {

    init(_ encryption: MessageBackupModel.Content.AssetContent.EncryptionAlgorithm) {
        switch encryption {
        case .aesCBC:
            self = .aesCbc
        case .aesGCM:
            self = .aesGcm
        }
    }

}

private extension Asset.Original.OneOf_MetaData {

    init?(_ metadata: MessageBackupModel.Content.AssetContent.Metadata) {
        switch metadata {

        case let .image(imageMetadata):
            self = .image(.with { image in
                image.width = imageMetadata.width
                image.height = imageMetadata.height
                if let tag = imageMetadata.tag, !tag.isEmpty {
                    image.tag = tag
                }
            })

        case let .video(videoMetadata):
            self = .video(.with { video in
                if let width = videoMetadata.width {
                    video.width = width
                }
                if let height = videoMetadata.height {
                    video.height = height
                }
                if let duration = videoMetadata.duration {
                    video.durationInMillis = duration
                }
            })

        case let .audio(audioMetadata):
            self = .audio(.with { audio in
                if let normalization = audioMetadata.normalization {
                    audio.normalizedLoudness = normalization
                }
                if let duration = audioMetadata.duration {
                    audio.durationInMillis = duration
                }
            })

        case let .generic:
            return nil
        }
    }

}

private func fallbackName(for metadata: MessageBackupModel.Content.AssetContent.Metadata) -> String? {
    switch metadata {

    case .image:
        "image"

    case .video:
        "video"

    case .audio:
        "audio"

    case let .generic(genericMetadata):
        if let name = genericMetadata.name, !name.isEmpty {
            name
        } else {
            "file"
        }
    }
}
