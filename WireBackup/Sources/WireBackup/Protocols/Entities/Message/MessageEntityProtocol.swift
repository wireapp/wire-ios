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
public import WireFoundation

public protocol MessageEntityProtocol {

    var id: String { get }
    var conversationID: QualifiedID { get }
    var senderUserID: QualifiedID { get }
    var senderClientID: String? { get }
    var creationDate: Date { get }
    var content: MessageContent { get }

}

// MARK: -

public enum MessageContent {

    case text(TextContent)
    case location(LocationContent)
    case asset(AssetContent)

}

// MARK: - Nested Types

public extension MessageContent {

    struct TextContent {
        public var text: String
    }

    struct LocationContent {
        public var longitude: Float
        public var latitude: Float
        public var name: String?
        public var zoom: Int32?
    }

    struct AssetContent {
        var mimeType: String
        var size: UInt64
        var name: String?
        var otrKey: Data
        var sha256: Data
        var assetID: String
        var assetToken: String?
        var assetDomain: String?
        var encryption: EncryptionAlgorithm?
        var metadata: Metadata?

        public enum EncryptionAlgorithm {
            case aesCBC
            case aesGCM
        }

        public enum Metadata {

            case image(ImageMetadata)
            case video(VideoMetadata)
            case audio(AudioMetadata)
            case generic(GenericMetadata)

        }
    }

}

public extension MessageContent.AssetContent.Metadata {

    struct ImageMetadata {
        var width: Int32
        var height: Int32
        var tag: String?
    }

    struct VideoMetadata {
        var width: Int32?
        var height: Int32?
        var duration: UInt64?
    }

    struct AudioMetadata {
        var normalization: Data?
        var duration: UInt64?
    }

    struct GenericMetadata {
        var name: String?
    }

}

// MARK: - Convenience

public extension MessageContent {

    static func text(
        _ text: String
    ) -> Self {
        .text(
            TextContent(
                text: text
            )
        )
    }

    static func location(
        longitude: Float,
        latitude: Float,
        name: String?,
        zoom: Int32?
    ) -> Self {
        .location(
            LocationContent(
                longitude: longitude,
                latitude: latitude,
                name: name,
                zoom: zoom
            )
        )
    }

    static func asset(
        mimeType: String,
        size: UInt64,
        name: String?,
        otrKey: Data,
        sha256: Data,
        assetID: String,
        assetToken: String?,
        assetDomain: String?,
        encryption: AssetContent.EncryptionAlgorithm?,
        metadata: AssetContent.Metadata?
    ) -> Self {
        .asset(
            AssetContent(
                mimeType: mimeType,
                size: size,
                name: name,
                otrKey: otrKey,
                sha256: sha256,
                assetID: assetID,
                assetToken: assetToken,
                assetDomain: assetDomain,
                encryption: encryption,
                metadata: metadata
            )
        )
    }

}

public extension MessageContent.AssetContent.Metadata {

    static func image(
        width: Int32,
        height: Int32,
        tag: String?
    ) -> Self {
        .image(
            ImageMetadata(
                width: width,
                height: height,
                tag: tag
            )
        )
    }

    static func video(
        width: Int32?,
        height: Int32?,
        duration: UInt64?
    ) -> Self {
        .video(
            VideoMetadata(
                width: width,
                height: height,
                duration: duration
            )
        )
    }

    static func audio(
        normalization: Data,
        duration: UInt64
    ) -> Self {
        .audio(
            AudioMetadata(
                normalization: normalization,
                duration: duration
            )
        )
    }

    static func generic(
        name: String?
    ) -> Self {
        .generic(
            GenericMetadata(
                name: name
            )
        )
    }

}
