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

    case text(TextMessageContent)
    case location(LocationMessageContent)
    case asset(AssetMessageContent)

}

// MARK: - Nested Types

extension CreateBackupMessageContent {

    public struct TextMessageContent {
        public var text: String
    }

    public struct LocationMessageContent {
        public var longitude: Float
        public var latitude: Float
        public var name: String?
        public var zoom: Int32?
    }

    public struct AssetMessageContent {
        var mimeType: String
        var size: UInt64
        var name: String?
        var otrKey: Data
        var sha256: Data
//        assetID: String
//        assetToken: String?
//        assetDomain: String?
//        encryption: EncryptionAlgorithm?
//        metaData: AssetMetadata?
    }

}

// MARK: - Convenience

extension CreateBackupMessageContent {

    public static func text(
        _ text: String
    ) -> Self {
        .text(
            TextMessageContent(
                text: text
            )
        )
    }

    public static func location(
        longitude: Float,
        latitude: Float,
        name: String?,
        zoom: Int32?
    ) -> Self {
        .location(
            LocationMessageContent(
                longitude: longitude,
                latitude: latitude,
                name: name,
                zoom: zoom
            )
        )
    }

    public static func asset(
        mimeType: String,
        size: UInt64,
        name: String?,
        otrKey: Data,
        sha256: Data
    ) -> Self {
        .asset(
            AssetMessageContent(
                mimeType: mimeType,
                size: size,
                name: name,
                otrKey: otrKey,
                sha256: sha256
            )
        )
    }

}
