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

        case .text(let text):
            BackupMessageContent.Text(
                text: text
            )

        case let .location(longitude, latitude, name, zoom):
            BackupMessageContent.Location(
                longitude: longitude,
                latitude: latitude,
                name: name,
                zoom: zoom.map { .init(int: $0) }
            )

        case let .asset(mimeType, size, name, otrKey, sha256):
            BackupMessageContent
                .Asset(
                    mimeType: mimeType,
                    size: Int32(size), // TODO: prevent conversion error
                    name: name,
                    otrKey: KotlinByteArray(otrKey),
                    sha256: KotlinByteArray(sha256),
                    assetId: "", // <#T##String#>,
                    assetToken: nil, // <#T##String?#>,
                    assetDomain: nil, // <#T##String?#>,
                    encryption: nil, // <#T##AssetEncryptionAlgorithm?#>,
                    metaData: nil, // <#T##AssetAssetMetadata?#>
                )

        }
    }
}
