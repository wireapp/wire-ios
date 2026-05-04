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
import KaliumBackup

extension WireBackup.MessageBackupModel.Content {

    init?(_ backupMessageContent: BackupMessageContent) {
        switch backupMessageContent {

        case let text as BackupMessageContent.Text:
            self = .text(TextContent(text))

        case let location as BackupMessageContent.Location:
            self = .location(LocationContent(location))

        case let asset as BackupMessageContent.Asset:
            self = .asset(AssetContent(asset))

        default:
            return nil
        }
    }

}

private extension WireBackup.MessageBackupModel.Content.TextContent {

    init(_ textContent: BackupMessageContent.Text) {
        self.init(
            text: textContent.text
        )
    }

}

extension WireBackup.MessageBackupModel.Content.LocationContent {

    init(_ locationContent: BackupMessageContent.Location) {
        self.init(
            longitude: locationContent.longitude,
            latitude: locationContent.latitude,
            name: locationContent.name,
            zoom: locationContent.zoom?.int32Value
        )
    }

}

extension WireBackup.MessageBackupModel.Content.AssetContent {

    init(_ assetContent: BackupMessageContent.Asset) {
        self.init(
            mimeType: assetContent.mimeType,
            size: UInt64(assetContent.size), // TODO: [WPB-16658] match data types between CoreCrypto, Kalium and iOS
            name: assetContent.name,
            otrKey: Data(assetContent.otrKey),
            sha256: Data(assetContent.sha256),
            assetID: assetContent.assetId,
            assetToken: assetContent.assetToken,
            assetDomain: assetContent.assetDomain,
            encryption: assetContent.encryption.map { EncryptionAlgorithm($0) },
            metadata: assetContent.metaData.flatMap { Metadata($0) }
        )
    }

}

extension MessageBackupModel.Content.AssetContent.EncryptionAlgorithm {

    init(_ encryptionAlgorithm: BackupMessageContent.AssetEncryptionAlgorithm) {
        switch encryptionAlgorithm {
        case .aesCbc:
            self = .aesCBC
        case .aesGcm:
            self = .aesGCM
        }
    }

}

extension MessageBackupModel.Content.AssetContent.Metadata {

    init?(_ metadata: BackupMessageContent.AssetAssetMetadata) {
        switch metadata {

        case let image as BackupMessageContent.AssetAssetMetadataImage:
            self = .image(ImageMetadata(image))

        case let video as BackupMessageContent.AssetAssetMetadataVideo:
            self = .video(VideoMetadata(video))

        case let audio as BackupMessageContent.AssetAssetMetadataAudio:
            self = .audio(AudioMetadata(audio))

        case let generic as BackupMessageContent.AssetAssetMetadataGeneric:
            self = .generic(GenericMetadata(generic))

        default:
            return nil
        }
    }

}

extension MessageBackupModel.Content.AssetContent.Metadata.ImageMetadata {

    init(_ imageMetadata: BackupMessageContent.AssetAssetMetadataImage) {
        self.init(
            width: imageMetadata.width,
            height: imageMetadata.height,
            tag: imageMetadata.tag
        )
    }

}

extension MessageBackupModel.Content.AssetContent.Metadata.VideoMetadata {

    init(_ videoMetadata: BackupMessageContent.AssetAssetMetadataVideo) {
        self.init(
            width: videoMetadata.width?.int32Value,
            height: videoMetadata.height?.int32Value,
            duration: videoMetadata.duration?.uint64Value
        )
    }

}

extension MessageBackupModel.Content.AssetContent.Metadata.AudioMetadata {

    init(_ audioMetadata: BackupMessageContent.AssetAssetMetadataAudio) {
        self.init(
            normalization: audioMetadata.normalization.map { Data($0) },
            duration: audioMetadata.duration?.uint64Value
        )
    }

}

extension MessageBackupModel.Content.AssetContent.Metadata.GenericMetadata {

    init(_ genericMetadata: BackupMessageContent.AssetAssetMetadataGeneric) {
        self.init(
            name: genericMetadata.name
        )
    }

}
