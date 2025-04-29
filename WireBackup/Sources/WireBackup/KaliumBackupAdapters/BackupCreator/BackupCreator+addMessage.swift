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

@preconcurrency import KaliumBackup
import KMPNativeCoroutinesAsync

extension BackupCreator {

    func addMessage(_ message: some MessageEntityProtocol) {

        let backupMessage = BackupMessage(
            id: message.id,
            conversationId: BackupQualifiedId(message.conversationID),
            senderUserId: BackupQualifiedId(message.senderUserID),
            senderClientId: message.senderClientID ?? "", // TODO: make optional
            creationDate: BackupDateTime(message.creationDate),
            content: BackupMessageContent(message.content),
            webPrimaryKey: nil // TODO: remove
        )
        mpBackupCreator.add(message: backupMessage)

    }

    private func BackupMessageContent(_ content: MessageContent) -> KaliumBackup.BackupMessageContent {
        switch content {

        case let .text(content):
            KaliumBackup.BackupMessageContent.Text(
                text: content.text
            )

        case let .location(content):
            KaliumBackup.BackupMessageContent.Location(
                longitude: content.longitude,
                latitude: content.latitude,
                name: content.name,
                zoom: content.zoom.map { KotlinInt(int: $0) }
            )

        case let .asset(content):
            KaliumBackup.BackupMessageContent.Asset(
                mimeType: content.mimeType,
                size: Int32(exactly: content.size) ?? 0,
                name: content.name,
                otrKey: KotlinByteArray(content.otrKey),
                sha256: KotlinByteArray(content.sha256),
                assetId: content.assetID,
                assetToken: content.assetToken,
                assetDomain: content.assetDomain,
                encryption: AssetEncryptionAlgorithm(content.encryption),
                metaData: AssetAssetMetadata(content.metadata)
            )
        }
    }

    private func AssetEncryptionAlgorithm(
        _ encryption: MessageContent.AssetContent.EncryptionAlgorithm?
    ) -> BackupMessageContent.AssetEncryptionAlgorithm? {
        switch encryption {

        case .aesCBC:
            .aesCbc

        case .aesGCM:
            .aesGcm

        case .none:
            .none
        }
    }

    private func AssetAssetMetadata(
        _ metadata: MessageContent.AssetContent.Metadata?
    ) -> BackupMessageContent.AssetAssetMetadata? {
        switch metadata {

        case let .image(metadata):
            KaliumBackup.BackupMessageContent.AssetAssetMetadataImage(
                width: metadata.width,
                height: metadata.height,
                tag: metadata.tag
            )

        case let .video(metadata):
            KaliumBackup.BackupMessageContent.AssetAssetMetadataVideo(
                width: metadata.width.map { KotlinInt(int: $0) },
                height: metadata.height.map { KotlinInt(int: $0) },
                duration: metadata.duration.map { KotlinLong(longLong: Int64($0)) },
            )

        case let .audio(metadata):
            KaliumBackup.BackupMessageContent.AssetAssetMetadataAudio(
                normalization: metadata.normalization.map { KotlinByteArray($0) },
                duration: metadata.duration.map { KotlinLong(longLong: Int64($0)) }
            )

        case let .generic(metadata):
            KaliumBackup.BackupMessageContent.AssetAssetMetadataGeneric(
                name: metadata.name
            )

        case .none:
            .none
        }
    }

}
