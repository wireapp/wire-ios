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

public import Foundation

public protocol CreateBackupMessageEntityProtocol: CreateBackupEntityProtocol {

    var id: String { get }
    var conversationID: QualifiedID { get }
    var senderUserID: QualifiedID { get }
    var senderClientID: String? { get }
    var creationDate: Date { get }
    var content: CreateBackupMessageContent { get }

}

public enum CreateBackupMessageContent {

    case text(_ content: String)

    case location(
        longitude: Float,
        latitude: Float,
        name: String?,
        zoom: Int32?
    )

    case asset(
        mimeType: String,
        size: UInt64,
        name: String?,
        otrKey: Data,
        sha256: Data,
//        assetID: String,
//        assetToken: String?,
//        assetDomain: String?,
//        encryption: EncryptionAlgorithm?,
//        metaData: AssetMetadata?
    )

}
