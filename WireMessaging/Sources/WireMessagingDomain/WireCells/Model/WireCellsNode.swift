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

public struct WireCellsPublicLinkID: Codable, Equatable, Hashable, Sendable {
    public let string: String

    package init(string: String) {
        self.string = string
    }
}

public struct WireCellsNode: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let path: String
    public let modified: Date?
    public let size: UInt64?
    public let eTag: String?
    public let type: WireCellsNodeType?
    public let isRecycled: Bool
    public let isDraft: Bool
    public let contentUrl: URL?
    public let contentHash: String?
    public let mimeType: String?
    public let previews: [WireCellsNodePreview]
    public let ownerUserID: QualifiedID?
    public let ownerUserName: String?
    public let conversationID: QualifiedID?
    public let publicLinkID: WireCellsPublicLinkID?
    public let tags: [String]

    /// A pre-signed URL to download the file. Note that this URL will expire so shouldn't be stored long-term.

    public let downloadURL: URL?

    package init(
        uuid: UUID,
        path: String,
        modified: Date? = nil,
        size: UInt64? = nil,
        eTag: String? = nil,
        type: WireCellsNodeType? = nil,
        isRecycled: Bool = false,
        isDraft: Bool = false,
        contentUrl: URL? = nil,
        contentHash: String? = nil,
        mimeType: String? = nil,
        previews: [WireCellsNodePreview] = [],
        ownerUserID: QualifiedID? = nil,
        ownerUserName: String? = nil,
        conversationID: QualifiedID? = nil,
        publicLinkID: WireCellsPublicLinkID? = nil,
        downloadURL: URL? = nil,
        tags: [String] = []
    ) {
        self.id = uuid
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
        self.ownerUserID = ownerUserID
        self.ownerUserName = ownerUserName
        self.conversationID = conversationID
        self.publicLinkID = publicLinkID
        self.downloadURL = downloadURL
        self.tags = tags
    }
}
