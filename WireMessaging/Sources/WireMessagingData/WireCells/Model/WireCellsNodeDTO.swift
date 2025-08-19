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

import CellsSDK
import WireFoundation
package import WireMessagingDomain
package import Foundation

package struct WireCellsNodeDTO: Equatable, Hashable, Sendable {
    package let uuid: UUID
    package let path: String
    package let modified: UInt64?
    package let size: UInt64?
    package let eTag: String?
    package let type: String?
    package let isRecycled: Bool
    package let isDraft: Bool
    package let contentUrl: URL?
    package let contentHash: String?
    package let mimeType: String?
    package let previews: [PreviewDTO]
    package let ownerUserId: String?
    package let ownerUserName: String?
    package let conversationId: String?
    package let publicLinkId: String?

    package init(
        uuid: UUID,
        path: String,
        modified: UInt64? = nil,
        size: UInt64? = nil,
        eTag: String? = nil,
        type: String? = nil,
        isRecycled: Bool = false,
        isDraft: Bool = false,
        contentUrl: URL? = nil,
        contentHash: String? = nil,
        mimeType: String? = nil,
        previews: [PreviewDTO] = [],
        ownerUserId: String? = nil,
        ownerUserName: String?,
        conversationId: String? = nil,
        publicLinkId: String? = nil
    ) {
        self.uuid = uuid
        self.path = path
        self.modified = modified
        self.size = size
        self.eTag = eTag
        self.type = type
        self.isRecycled = isRecycled
        self.isDraft = isDraft
        self.contentUrl = contentUrl
        self.contentHash = contentHash
        self.mimeType = mimeType
        self.previews = previews
        self.ownerUserId = ownerUserId
        self.ownerUserName = ownerUserName
        self.conversationId = conversationId
        self.publicLinkId = publicLinkId
    }
}

package extension WireCellsNodeDTO {
    func toDomainModel() -> WireCellsNode {
        WireCellsNode(
            uuid: uuid,
            path: path,
            modified: modified,
            size: size,
            eTag: eTag,
            type: type,
            isRecycled: isRecycled,
            isDraft: isDraft,
            contentUrl: contentUrl,
            contentHash: contentHash,
            mimeType: mimeType,
            previews: previews.map { $0.toModel() },
            ownerUserID: ownerUserId.flatMap { QualifiedID(string: $0) },
            conversationID: conversationId.flatMap(WireCellsConversationID.init(string:)),
            publicLinkID: publicLinkId.map(WireCellsPublicLinkID.init(string:))
        )
    }
}

package extension WireCellsNode {
    func toDTO() -> WireCellsNodeDTO {
        WireCellsNodeDTO(
            uuid: id,
            path: path,
            modified: modified,
            size: size,
            eTag: eTag,
            type: type,
            isRecycled: isRecycled,
            isDraft: isDraft,
            contentUrl: contentUrl,
            contentHash: contentHash,
            mimeType: mimeType,
            previews: previews.map { PreviewDTO(url: $0.url, dimension: $0.dimension) },
            ownerUserId: ownerUserID?.transportString,
            ownerUserName: ownerUserName,
            conversationId: conversationID?.pydioQualifiedID,
            publicLinkId: publicLinkID?.string
        )
    }
}

package extension RestNode {
    func toDTO() -> WireCellsNodeDTO? {
        guard let uuid = UUID(uuidString: uuid) else { return nil }

        return WireCellsNodeDTO(
            uuid: uuid,
            path: path,
            modified: modified.flatMap(UInt64.init),
            size: size.flatMap(UInt64.init),
            eTag: storageETag,
            type: type?.rawValue ?? "",
            isRecycled: isRecycled ?? false,
            isDraft: isDraft ?? false,
            contentUrl: preSignedGET?.url.flatMap(URL.init(string:)),
            contentHash: contentHash,
            mimeType: contentType,
            previews: previews?.compactMap { preview -> PreviewDTO? in
                guard let urlString = preview.preSignedGET?.url else { return nil }
                guard let url = URL(string: urlString) else { return nil }
                return PreviewDTO(url: url, dimension: preview.dimension ?? 0)
            } ?? [],
            ownerUserId: userMetadata?
                .first(where: { $0.namespace == "usermeta-owner-uuid" })?
                .valueAsString,
            ownerUserName: userMetadata?
                .first(where: { $0.namespace == "usermeta-owner" })?
                .valueAsString,
            conversationId: contextWorkspace?.uuid,
            publicLinkId: shares?.first?.uuid
        )
    }
}

package struct PreviewDTO: Equatable, Hashable, Sendable {
    package let url: URL
    package let dimension: Int?
}

package extension PreviewDTO {
    func toModel() -> WireCellsNodePreview {
        WireCellsNodePreview(
            url: url,
            dimension: dimension ?? 0
        )
    }
}

private extension WireFoundation.QualifiedID {

    /// Creates a QualifiedID from a string in the format `domain@uuid`.
    init?(string: String) {
        let components = string.split(separator: "@")
        guard components.count == 2, let uuid = UUID(uuidString: String(components[1])) else {
            return nil
        }
        self.init(id: uuid, domain: String(components[0]))
    }

    var transportString: String {
        return "\(domain)@\(id.uuidString.lowercased())"
    }
}

private extension RestUserMeta {
    var valueAsString: String? {
        try? JSONDecoder().decode(String.self, from: Data(jsonValue.utf8))
    }
}
