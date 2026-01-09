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

public import Foundation
public import WireFoundation

public struct MessageBackupModel: Hashable, Sendable {

    public var id: String
    public var conversationID: QualifiedID
    public var senderUserID: QualifiedID
    public var senderClientID: String?
    public var creationDate: Date
    public var content: Content

    public init(
        id: String,
        conversationID: QualifiedID,
        senderUserID: QualifiedID,
        senderClientID: String?,
        creationDate: Date,
        content: Content
    ) {
        self.id = id
        self.conversationID = conversationID
        self.senderUserID = senderUserID
        self.senderClientID = senderClientID?.isEmpty == true ? nil : senderClientID
        self.creationDate = creationDate
        self.content = content
    }

}

// MARK: -

// The following types replicate the API of the multi-platform backup library in a Swift friendlier way.
// (e.g. enums instead of class hierarchy)

public extension MessageBackupModel {

    enum Content: Hashable, Sendable {

        case text(TextContent)
        case location(LocationContent)
        case asset(AssetContent)

    }

}

// MARK: - Nested Types

public extension MessageBackupModel.Content {

    struct TextContent: Hashable, Sendable {
        public var text: String
    }

    struct LocationContent: Hashable, Sendable {
        public var longitude: Float
        public var latitude: Float
        public var name: String?
        public var zoom: Int32?
    }

    struct AssetContent: Hashable, Sendable {

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

        public enum EncryptionAlgorithm: String, Hashable, Sendable {
            case aesCBC
            case aesGCM
        }

        public enum Metadata: Hashable, Sendable {
            case image(ImageMetadata)
            case video(VideoMetadata)
            case audio(AudioMetadata)
            case generic(GenericMetadata)
        }

    }

}

public extension MessageBackupModel.Content.AssetContent.Metadata {

    struct ImageMetadata: Hashable, Sendable {
        public var width: Int32
        public var height: Int32
        public var tag: String?
    }

    struct VideoMetadata: Hashable, Sendable {
        public var width: Int32?
        public var height: Int32?
        public var duration: UInt64?
    }

    struct AudioMetadata: Hashable, Sendable {
        public var normalization: Data?
        public var duration: UInt64?
    }

    struct GenericMetadata: Hashable, Sendable {
        public var name: String?
    }

}

// MARK: - Convenience

public extension MessageBackupModel.Content {

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

    var isText: Bool {
        if case .text = self { return true }
        return false
    }

    var isLocation: Bool {
        if case .location = self { return true }
        return false
    }

    var isAsset: Bool {
        if case .asset = self { return true }
        return false
    }
}

public extension MessageBackupModel.Content.AssetContent.Metadata {

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
