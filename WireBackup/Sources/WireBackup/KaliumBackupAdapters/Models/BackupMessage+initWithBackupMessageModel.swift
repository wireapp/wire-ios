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

extension BackupMessage {

    convenience init(_ message: MessageBackupModel) {
        self.init(
            id: message.id.lowercased(),
            conversationId: BackupQualifiedId(message.conversationID),
            senderUserId: BackupQualifiedId(message.senderUserID),
            senderClientId: message.senderClientID?.lowercased() ?? "",
            creationDate: BackupDateTime(message.creationDate),
            content: backupMessageContent(message.content),
            webPrimaryKey: nil
        )
    }

}

private func backupMessageContent(_ content: MessageBackupModel.Content) -> BackupMessageContent {
    switch content {

    case let .text(content):
        BackupMessageContent.Text(
            text: content.text
        )

    case let .location(content):
        BackupMessageContent.Location(
            longitude: content.longitude,
            latitude: content.latitude,
            name: content.name,
            zoom: content.zoom.map { KotlinInt(int: $0) }
        )

    case let .asset(content):
        BackupMessageContent.Asset(
            mimeType: content.mimeType,
            size: Int32(exactly: content.size) ?? 0,
            name: content.name,
            otrKey: KotlinByteArray(content.otrKey),
            sha256: KotlinByteArray(content.sha256),
            assetId: content.assetID,
            assetToken: content.assetToken,
            assetDomain: content.assetDomain,
            encryption: content.encryption.map { assetEncryptionAlgorithm($0) },
            metaData: content.metadata.map { assetAssetMetadata($0) }
        )
    }
}

private func assetEncryptionAlgorithm(
    _ encryption: MessageBackupModel.Content.AssetContent.EncryptionAlgorithm
) -> BackupMessageContent.AssetEncryptionAlgorithm {
    switch encryption {
    case .aesCBC:
        .aesCbc
    case .aesGCM:
        .aesGcm
    }
}

private func assetAssetMetadata(
    _ metadata: MessageBackupModel.Content.AssetContent.Metadata
) -> BackupMessageContent.AssetAssetMetadata {
    switch metadata {

    case let .image(metadata):
        BackupMessageContent.AssetAssetMetadataImage(
            width: metadata.width,
            height: metadata.height,
            tag: metadata.tag
        )

    case let .video(metadata):
        BackupMessageContent.AssetAssetMetadataVideo(
            width: metadata.width.map { KotlinInt(int: $0) },
            height: metadata.height.map { KotlinInt(int: $0) },
            duration: metadata.duration.map { KotlinLong(value: Int64($0)) }
        )

    case let .audio(metadata):
        BackupMessageContent.AssetAssetMetadataAudio(
            normalization: metadata.normalization.map { KotlinByteArray($0) },
            duration: metadata.duration.map { KotlinLong(value: Int64($0)) }
        )

    case let .generic(metadata):
        BackupMessageContent.AssetAssetMetadataGeneric(
            name: metadata.name
        )
    }
}
