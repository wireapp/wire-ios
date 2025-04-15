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

public struct WireCellsNodeID: Codable, Equatable, Hashable, Identifiable, Sendable {
    package let uuid: UUID
    package let versionID: String

    public var id: String {
        uuid.uuidString + versionID
    }

    package init(uuid: UUID, versionID: String) {
        self.uuid = uuid
        self.versionID = versionID
    }
}

public struct WireCellsPublicLinkID: Codable, Equatable, Hashable, Sendable {
    public let string: String

    package init(string: String) {
        self.string = string
    }
}

public struct WireCellsCellNode: Equatable, Identifiable, Sendable {
    public let id: WireCellsNodeID

    public let path: String
    public let modified: Int64?
    public let size: Int64?
    public let eTag: String?
    public let type: String?
    public let isRecycled: Bool
    public let isDraft: Bool
    public let contentUrl: URL?
    public let contentHash: String?
    public let mimeType: String?
    public let previews: [WireCellsNodePreview]
    public let ownerUserId: String?
    public let conversationId: WireCellsConversationID?
    public let publicLinkId: WireCellsPublicLinkID?

    package init(
        uuid: UUID,
        versionID: String,
        path: String,
        modified: Int64? = nil,
        size: Int64? = nil,
        eTag: String? = nil,
        type: String? = nil,
        isRecycled: Bool = false,
        isDraft: Bool = false,
        contentUrl: URL? = nil,
        contentHash: String? = nil,
        mimeType: String? = nil,
        previews: [WireCellsNodePreview] = [],
        ownerUserId: String? = nil,
        conversationId: WireCellsConversationID? = nil,
        publicLinkId: WireCellsPublicLinkID? = nil
    ) {
        self.id = WireCellsNodeID(uuid: uuid, versionID: versionID)
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
