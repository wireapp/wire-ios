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

import Foundation

public final class AssetRequestFactory: NSObject {

    public enum Retention: String {
        /// The asset will be automatically removed from the backend
        /// storage after a short-ish amount of time.
        case volatile

        /// The asset will be automatically removed from the backend storage
        /// after a certain, long-ish amount of time.
        case expiring

        /// The asset will never be removed from the backend storage unless the
        /// user requests the deletion explicitly. Used for profile pictures.
        case eternal

        /// The same as eternal, however this is cost-optimized
        /// on the backend for infrequent access. Used for team conversations.
        case eternalInfrequentAccess = "eternal-infrequent_access"
    }

    public struct AssetAuditLogMetaData {

        public let conversationID: QualifiedID
        public let fileName: String
        public let mimeType: String

        public init(
            conversationID: QualifiedID,
            fileName: String,
            mimeType: String?
        ) {
            self.conversationID = conversationID
            self.fileName = fileName

            if let mimeType, !mimeType.isEmpty {
                self.mimeType = mimeType
            } else {
                // Fallback to "raw bytes".
                self.mimeType = "application/octet-stream"
            }
        }
    }

    private enum Constant {
        static let md5 = "Content-MD5"
        static let accessLevel = "public"
        static let retention = "retention"
        static let boundary = "frontier"
        static let conversationID = "convId"
        static let id = "id"
        static let domain = "domain"
        static let fileName = "filename"
        static let mimetype = "filetype"

        enum ContentType {
            static let json = "application/json"
            static let octetStream = "application/octet-stream"
            static let multipart = "multipart/mixed; boundary=frontier"
        }
    }

    public func backgroundUpstreamRequestForAsset(
        message: ZMAssetClientMessage,
        withData data: Data,
        shareable: Bool = true,
        retention: Retention,
        assetAuditLogMetaData: AssetAuditLogMetaData?,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {
        guard let uploadURL = uploadURL(
            for: message,
            in: message.managedObjectContext!,
            shareable: shareable,
            retention: retention,
            assetAuditLogMetaData: assetAuditLogMetaData,
            data: data
        ) else {
            return nil
        }

        let path = switch apiVersion {
        case .v0, .v1:
            "/assets/v3"

        case .v2, .v3, .v4, .v5, .v6, .v7, .v8, .v9, .v10, .v11, .v12, .v13:
            "/assets"
        }

        let request = ZMTransportRequest.uploadRequest(
            withFileURL: uploadURL,
            path: path,
            contentType: Constant.ContentType.multipart,
            apiVersion: apiVersion.rawValue
        )

        // [WPB-7392] through a refactoring the `contentHintForRequestLoop` was seperated form
        // `addContentDebugInformation`.
        // Not clear if it is necessary to set `contentHintForRequestLoop` here, but keep the original behavior.
        request.addContentDebugInformation("Uploading full asset to \(path)")
        request.contentHintForRequestLoop += "Uploading full asset to \(path)"

        return request
    }

    public func upstreamRequestForAsset(
        withData data: Data,
        shareable: Bool = true,
        retention: Retention,
        assetAuditLogMetaData: AssetAuditLogMetaData?,
        apiVersion: APIVersion
    ) -> ZMTransportRequest? {
        guard let multipartData = try? dataForMultipartAssetUploadRequest(
            data,
            shareable: shareable,
            retention: retention,
            assetAuditLogMetaData: assetAuditLogMetaData
        ) else { return nil }

        let path = switch apiVersion {
        case .v0, .v1:
            "/assets/v3"

        case .v2, .v3, .v4, .v5, .v6, .v7, .v8, .v9, .v10, .v11, .v12, .v13:
            "/assets"
        }

        return ZMTransportRequest(
            path: path,
            method: .post,
            binaryData: multipartData,
            type: Constant.ContentType.multipart,
            contentDisposition: nil,
            apiVersion: apiVersion.rawValue
        )
    }

    func dataForMultipartAssetUploadRequest(
        _ data: Data,
        shareable: Bool,
        retention: Retention,
        assetAuditLogMetaData: AssetAuditLogMetaData?
    ) throws -> Data {
        let fileDataHeader = [Constant.md5: data.zmMD5Digest().base64String()]
        var jsonObject: [String: Any] = [
            Constant.accessLevel: shareable,
            Constant.retention: retention.rawValue
        ]

        if let metaData = assetAuditLogMetaData {
            jsonObject[Constant.conversationID] = [
                Constant.id: metaData.conversationID.uuid.transportString(),
                Constant.domain: metaData.conversationID.domain
            ]
            jsonObject[Constant.fileName] = metaData.fileName
            jsonObject[Constant.mimetype] = metaData.mimeType
        }

        let metaData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])

        return NSData.multipartData(withItems: [
            ZMMultipartBodyItem(data: metaData, contentType: Constant.ContentType.json, headers: nil),
            ZMMultipartBodyItem(data: data, contentType: Constant.ContentType.octetStream, headers: fileDataHeader)
        ], boundary: Constant.boundary)
    }

    private func uploadURL(
        for message: ZMAssetClientMessage,
        in moc: NSManagedObjectContext,
        shareable: Bool,
        retention: Retention,
        assetAuditLogMetaData: AssetAuditLogMetaData?,
        data: Data
    ) -> URL? {
        guard let multipartData = try? dataForMultipartAssetUploadRequest(
            data,
            shareable: shareable,
            retention: retention,
            assetAuditLogMetaData: assetAuditLogMetaData,
        ) else {
            return nil
        }

        return moc.zm_fileAssetCache.storeTransportData(
            multipartData,
            for: message
        )
    }

}

public extension AssetRequestFactory.Retention {
    init(conversation: ZMConversation) {
        if ZMUser.selfUser(in: conversation.managedObjectContext!).hasTeam || conversation.hasTeam || conversation
            .containsTeamUser {
            self = .eternalInfrequentAccess
        } else {
            self = .expiring
        }
    }
}

extension ZMConversation {
    var containsTeamUser: Bool {
        localParticipants.any { $0.hasTeam }
    }

    var hasTeam: Bool {
        team != nil
    }
}
