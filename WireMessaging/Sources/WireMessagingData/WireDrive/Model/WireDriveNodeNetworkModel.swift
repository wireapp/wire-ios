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

import CellsSDK
import UniformTypeIdentifiers
import WireFoundation
package import WireMessagingDomain
package import Foundation

package struct WireDriveNodeNetworkModel: Equatable, Hashable, Sendable {
    package let uuid: UUID
    package let path: String
    package let modified: UInt64?
    package let size: UInt64?
    package let eTag: String?
    package let type: String?
    package let isRecycled: Bool
    package let isDraft: Bool
    package let isEditable: Bool
    package let contentUrl: URL?
    package let contentHash: String?
    package let mimeType: String?
    package let previews: [PreviewDTO]
    package let ownerUserId: String?
    package let ownerUserName: String?
    package let conversationId: String?
    package let publicLinkID: String?
    package let downloadURL: URL?
    package let tags: [String]

    package init(
        uuid: UUID,
        path: String,
        modified: UInt64? = nil,
        size: UInt64? = nil,
        eTag: String? = nil,
        type: String? = nil,
        isRecycled: Bool = false,
        isDraft: Bool = false,
        isEditable: Bool = false,
        contentUrl: URL? = nil,
        contentHash: String? = nil,
        mimeType: String? = nil,
        previews: [PreviewDTO] = [],
        ownerUserId: String? = nil,
        ownerUserName: String?,
        conversationId: String? = nil,
        publicLinkID: String? = nil,
        downloadURL: URL? = nil,
        tags: [String] = []
    ) {
        self.uuid = uuid
        self.path = path
        self.modified = modified
        self.size = size
        self.eTag = eTag
        self.type = type
        self.isRecycled = isRecycled
        self.isDraft = isDraft
        self.isEditable = isEditable
        self.contentUrl = contentUrl
        self.contentHash = contentHash
        self.mimeType = mimeType
        self.previews = previews
        self.ownerUserId = ownerUserId
        self.ownerUserName = ownerUserName
        self.conversationId = conversationId
        self.publicLinkID = publicLinkID
        self.downloadURL = downloadURL
        self.tags = tags
    }
}

package extension WireDriveNodeNetworkModel {
    func toDomainModel(conversations: [WireDriveConversation]) -> WireDriveNode {
        WireDriveNode(
            uuid: uuid,
            conversation: matchingConversation(in: conversations),
            path: path,
            modified: modified.map { Date(timeIntervalSince1970: Double($0)) },
            size: size,
            eTag: eTag,
            type: type.flatMap { WireDriveNodeType(rawValue: $0) },
            isRecycled: isRecycled,
            isDraft: isDraft,
            isEditable: isEditable,
            contentUrl: contentUrl,
            contentHash: contentHash,
            mimeType: mimeType,
            previews: previews.map { $0.toModel() },
            ownerUserID: ownerUserId.flatMap { QualifiedID(string: $0) },
            ownerUserName: ownerUserName,
            conversationID: conversationId.flatMap(QualifiedID.init(string:)),
            publicLinkID: publicLinkID.map(WireDrivePublicLinkID.init(string:)),
            downloadURL: downloadURL,
            tags: tags
        )
    }

    private func matchingConversation(
        in conversations: [WireDriveConversation]
    ) -> WireDriveConversation? {
        let url = URL(fileURLWithPath: path)

        guard let firstPathComponent = url.pathComponents.dropFirst().first else {
            return nil
        }

        return conversations.first { $0.id == firstPathComponent }
    }
}

package extension WireDriveNode {
    func toDTO() -> WireDriveNodeNetworkModel {
        WireDriveNodeNetworkModel(
            uuid: id,
            path: path,
            modified: modified.map { UInt64($0.timeIntervalSince1970) },
            size: size,
            eTag: eTag,
            type: type?.rawValue,
            isRecycled: isRecycled,
            isDraft: isDraft,
            contentUrl: contentUrl,
            contentHash: contentHash,
            mimeType: mimeType,
            previews: previews.map { PreviewDTO(url: $0.url, dimension: $0.dimension, processing: $0.processing) },
            ownerUserId: ownerUserID?.transportString,
            ownerUserName: ownerUserName,
            conversationId: conversationID?.transportString,
            publicLinkID: publicLinkID?.string,
            tags: tags
        )
    }
}

package extension RestNode {
    func toDTO() -> WireDriveNodeNetworkModel? {
        guard let uuid = UUID(uuidString: uuid) else { return nil }

        return WireDriveNodeNetworkModel(
            uuid: uuid,
            path: path,
            modified: modified.flatMap(UInt64.init),
            size: size.flatMap(UInt64.init),
            eTag: storageETag,
            type: type?.rawValue ?? "",
            isRecycled: isRecycled ?? false,
            isDraft: isDraft ?? false,
            isEditable: editorURLsKeys?.contains("collabora") ?? false,
            contentUrl: preSignedGET?.url.flatMap(URL.init(string:)),
            contentHash: contentHash,
            mimeType: contentType,
            previews: previews?.compactMap { preview -> PreviewDTO? in
                PreviewDTO(preview)
            } ?? [],
            ownerUserId: metadataString("usermeta-owner-uuid"),
            ownerUserName: metadataString("usermeta-owner"),
            conversationId: contextWorkspace?.uuid,
            publicLinkID: shares?.first?.uuid,
            downloadURL: preSignedGET?.url.flatMap(URL.init(string:)),
            tags: metadataString("usermeta-tags")?
                .split(separator: ",").map { String($0) } ?? []
        )
    }

    private func metadataString(_ namespace: String) -> String? {
        userMetadata?
            .first { $0.namespace == namespace }?
            .valueAsString
    }
}

package struct PreviewDTO: Equatable, Hashable, Sendable {
    package let url: URL?
    package let dimension: Int?
    package let processing: Bool?

    init(url: URL?, dimension: Int?, processing: Bool?) {
        self.url = url
        self.dimension = dimension
        self.processing = processing
    }

    init?(_ value: RestFilePreview) {
        var url: URL?

        if let urlString = value.preSignedGET?.url, let contentType = value.contentType {
            guard let previewURL = URL(string: urlString),
                  let type = UTType(mimeType: contentType),
                  type.conforms(to: .image) else {
                return nil
            }
            url = previewURL
        }

        self.url = url
        self.dimension = value.dimension
        self.processing = value.processing
    }

}

package extension PreviewDTO {
    func toModel() -> WireDriveNodePreview {
        WireDriveNodePreview(
            url: url,
            dimension: dimension ?? 0,
            processing: processing ?? false
        )
    }
}

private extension WireFoundation.QualifiedID {

    /// Creates a QualifiedID from a string in the format `uuid@domain`.
    init?(string: String) {
        let components = string.split(separator: "@")
        guard components.count == 2, let uuid = UUID(uuidString: String(components[0])) else {
            return nil
        }
        self.init(id: uuid, domain: String(components[1]))
    }

    var transportString: String {
        "\(id.transportString())@\(domain)"
    }
}

private extension RestUserMeta {
    var valueAsString: String? {
        try? JSONDecoder().decode(String.self, from: Data(jsonValue.utf8))
    }
}
