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

import Foundation
import UniformTypeIdentifiers
import WireMessagingDomain

extension WireDriveDraft {
    static func fixture(
        nodeID: UUID = UUID(),
        versionID: UUID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        assetURL: URL = URL(string: "https://example.com")!,
        fileType: UTType? = nil,
        status: WireDriveUploadStatus = .uploaded(isDraft: true),
        name: String = "Draft",
        bytes: Int = 1024,
        mimeType: String? = nil,
        requiresCleanup: Bool = false,
        metadata: WireDriveDraft.Metadata? = nil
    ) -> WireDriveDraft {
        WireDriveDraft(
            nodeID: nodeID,
            versionID: versionID,
            assetURL: assetURL,
            fileType: fileType,
            status: status,
            name: name,
            bytes: bytes,
            mimeType: mimeType,
            requiresCleanup: requiresCleanup,
            metadata: metadata
        )
    }
}
