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
package import Foundation

package struct WireCellsCellNodeDTO: Equatable, Hashable, Sendable {
    package let uuid: UUID
    package let versionId: UUID
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
    package let previews: [PreviewDto]
    package let ownerUserId: String?
    package let conversationId: String?
    package let publicLinkId: String?

    package init(
        uuid: UUID,
        versionId: UUID,
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
        previews: [PreviewDto] = [],
        ownerUserId: String? = nil,
        conversationId: String? = nil,
        publicLinkId: String? = nil
    ) {
        self.uuid = uuid
        self.versionId = versionId
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
        self.conversationId = conversationId
        self.publicLinkId = publicLinkId
    }
}

package extension WireCellsCellNodeDTO {
    func toModel() -> WireCellsCellNode {
        WireCellsCellNode(
            uuid: uuid,
            versionID: versionId,
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
            ownerUserID: ownerUserId,
            conversationID: conversationId.flatMap(WireCellsConversationID.init(string:)),
            publicLinkID: publicLinkId.map(WireCellsPublicLinkID.init(string:))
        )
    }
}

package extension WireCellsCellNode {
    func toDto() -> WireCellsCellNodeDTO {
        WireCellsCellNodeDTO(
            uuid: id.uuid,
            versionId: id.versionID,
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
            previews: previews.map { PreviewDto(url: $0.url, dimension: $0.dimension) },
            ownerUserId: ownerUserID,
            conversationId: conversationID?.pydioQualifiedID,
            publicLinkId: publicLinkID?.string
        )
    }
}

package extension RestNode {
    func toDto() -> WireCellsCellNodeDTO? {
        guard let uuid = UUID(uuidString: uuid) else { return nil }
        // `versionMeta` is optional in the API response. Need to check with Charles if it can actually be nil, and
        // when.
        // What should we do in that case?
        guard let versionMeta, let versionID = UUID(uuidString: versionMeta.versionId) else { return nil }
        return WireCellsCellNodeDTO(
            uuid: uuid,
            versionId: versionID,
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
            previews: previews?.compactMap { preview -> PreviewDto? in
                guard let urlString = preview.preSignedGET?.url else { return nil }
                guard let url = URL(string: urlString) else { return nil }
                return PreviewDto(url: url, dimension: preview.dimension ?? 0)
            } ?? [],
            ownerUserId: userMetadata?
                .first(where: { $0.namespace == "usermeta-owner-uuid" })?
                .jsonValue.trimmingCharacters(in: CharacterSet(charactersIn: "\"")),
            conversationId: contextWorkspace?.uuid,
            publicLinkId: shares?.first?.uuid
        )
    }
}

package struct PreviewDto: Equatable, Hashable, Sendable {
    package let url: URL
    package let dimension: Int?
}

package extension PreviewDto {
    func toModel() -> WireCellsNodePreview {
        WireCellsNodePreview(
            url: url,
            dimension: dimension ?? 0
        )
    }
}
