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

public struct BackupMessageModel: Encodable, Hashable, Sendable {
    public typealias ID = String

    public var id: ID
    public var conversationID: QualifiedID
    public var senderUserID: QualifiedID
    public var senderClientID: String?
    public var creationDate: Date
    public var content: Content

    public init(
        id: ID,
        conversationID: QualifiedID,
        senderUserID: QualifiedID,
        senderClientID: String?,
        creationDate: Date,
        content: Content
    ) {
        self.id = id
        self.conversationID = conversationID
        self.senderUserID = senderUserID
        self.senderClientID = senderClientID
        self.creationDate = creationDate
        self.content = content
    }

}

// MARK: -

// The following types replicate the API of the multi-platform backup library in a Swift friendlier way.
// (e.g. enums instead of class hierarchy)

extension BackupMessageModel {

    public enum Content: Encodable, Hashable, Sendable {

        case text(TextContent)
        case location(LocationContent)
        case asset(AssetContent)

    }

}

// MARK: - Nested Types

public extension BackupMessageModel.Content {

    struct TextContent: Encodable, Hashable, Sendable {

        public var text: String

        // This property is used by the Codable implementation and is not to be used otherwise.
        private var type = "text"

        public init(text: String) {
            self.text = text
        }

    }

    struct LocationContent: Encodable, Hashable, Sendable {

        public var longitude: Float
        public var latitude: Float
        public var name: String?
        public var zoom: Int32?

        // This property is used by the Codable implementation and is not to be used otherwise.
        private var type = "location"

        public init(longitude: Float, latitude: Float, name: String?, zoom: Int32?) {
            self.longitude = longitude
            self.latitude = latitude
            self.name = name
            self.zoom = zoom
        }

    }

    struct AssetContent: Encodable, Hashable, Sendable {

        public var mimeType: String
        public var size: UInt64
        public var name: String?
        public var otrKey: Data
        public var sha256: Data
        public var assetID: String
        public var assetToken: String?
        public var assetDomain: String?
        public var encryption: EncryptionAlgorithm?
        public var metadata: Metadata?

        // This property is used by the Codable implementation and is not to be used otherwise.
        private var type = "asset"

        public init(
            mimeType: String,
            size: UInt64,
            name: String?,
            otrKey: Data,
            sha256: Data,
            assetID: String,
            assetToken: String?,
            assetDomain: String?,
            encryption: EncryptionAlgorithm?,
            metadata: Metadata?
        ) {
            self.mimeType = mimeType
            self.size = size
            self.name = name
            self.otrKey = otrKey
            self.sha256 = sha256
            self.assetID = assetID
            self.assetToken = assetToken
            self.assetDomain = assetDomain
            self.encryption = encryption
            self.metadata = metadata
        }

        public enum EncryptionAlgorithm: String, Encodable, Hashable, Sendable {
            case aesCBC
            case aesGCM
        }

        public enum Metadata: Encodable, Hashable, Sendable {

            case image(ImageMetadata)
            case video(VideoMetadata)
            case audio(AudioMetadata)
            // TODO: [WPB-16658] check if the `.generic` case needs to be used
            case generic(GenericMetadata)

        }

    }

}

public extension BackupMessageModel.Content.AssetContent.Metadata {

    struct ImageMetadata: Encodable, Hashable, Sendable {

        public var width: Int32
        public var height: Int32
        public var tag: String?

        // This property is used by the Codable implementation and is not to be used otherwise.
        private var type = "image"

        public init(width: Int32, height: Int32, tag: String?) {
            self.width = width
            self.height = height
            self.tag = tag
        }

    }

    struct VideoMetadata: Encodable, Hashable, Sendable {

        public var width: Int32?
        public var height: Int32?
        public var duration: UInt64?

        // This property is used by the Codable implementation and is not to be used otherwise.
        private var type = "video"

        public init(width: Int32?, height: Int32?, duration: UInt64?) {
            self.width = width
            self.height = height
            self.duration = duration
        }

    }

    struct AudioMetadata: Encodable, Hashable, Sendable {

        public var normalization: Data?
        public var duration: UInt64?

        // This property is used by the Codable implementation and is not to be used otherwise.
        private var type = "audio"

        public init(normalization: Data?, duration: UInt64?) {
            self.normalization = normalization
            self.duration = duration
        }

    }

    struct GenericMetadata: Encodable, Hashable, Sendable {

        public var name: String?

        // This property is used by the Codable implementation and is not to be used otherwise.
        private var type = "generic"

        public init(name: String?) {
            self.name = name
        }

    }

}

// MARK: - Convenience

public extension BackupMessageModel.Content {

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

public extension BackupMessageModel.Content.AssetContent.Metadata {

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
