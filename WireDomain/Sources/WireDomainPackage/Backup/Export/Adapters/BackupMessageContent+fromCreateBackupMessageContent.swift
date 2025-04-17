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

extension BackupMessageContent {

    static func from(_ content: CreateBackupMessageContent) -> BackupMessageContent {
        switch content {

        case .text(let content):
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
                encryption: nil, // T##AssetEncryptionAlgorithm?,
                metaData: nil, // <#T##AssetAssetMetadata?#>
            )

        }
    }
}
