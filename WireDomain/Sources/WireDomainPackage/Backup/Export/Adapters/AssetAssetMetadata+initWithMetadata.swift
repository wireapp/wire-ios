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

import WireBackup

extension BackupMessageContent.AssetAssetMetadata {

    static func from(
        _ metadata: CreateBackupMessageContent.AssetContent.Metadata
    ) -> BackupMessageContent.AssetAssetMetadata {
        switch metadata {

        case .image(let metadata):
            BackupMessageContent.AssetAssetMetadataImage(
                width: metadata.width,
                height: metadata.height,
                tag: metadata.tag
            )

        case .video(let metadata):
            BackupMessageContent.AssetAssetMetadataVideo(
                width: metadata.width.map { KotlinInt(int: $0) },
                height: metadata.height.map { KotlinInt(int: $0) },
                duration: metadata.duration.map { KotlinLong(longLong: Int64($0)) }, // TODO: types should match CoreCrypto types
            )

        case .audio(let metadata):
            BackupMessageContent.AssetAssetMetadataAudio(
                normalization: metadata.normalization.map { KotlinByteArray($0) },
                duration: metadata.duration.map { KotlinLong(longLong: Int64($0)) }
            )

        case .generic(let metadata):
            BackupMessageContent.AssetAssetMetadataGeneric(
                name: metadata.name
            )

        }
    }
}
