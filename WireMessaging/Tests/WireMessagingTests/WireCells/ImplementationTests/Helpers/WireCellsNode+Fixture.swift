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
import WireFoundation
import WireMessagingDomain

extension WireCellsNode {
    static func fixture(
        uuid: UUID = UUID(),
        path: String = "some/path",
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
        downloadURL: URL? = nil
    ) -> WireCellsNode {
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
            previews: previews,
            ownerUserID: ownerUserID,
            ownerUserName: ownerUserName,
            conversationID: conversationID,
            publicLinkID: publicLinkID,
            downloadURL: downloadURL
        )
    }
}
