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

public struct WireCellsMessageAttachmentDraftEntityID: Codable, Equatable, Hashable, Identifiable, Sendable {
    public let uuid: UUID
    public let versionID: String

    public var id: String {
        "\(uuid.uuidString)/\(versionID)"
    }

    package init(uuid: UUID, versionID: String) {
        self.uuid = uuid
        self.versionID = versionID
    }
}

extension WireCellsMessageAttachmentDraftEntityID: CustomStringConvertible {
    public var description: String {
        "\(uuid.uuidString)/\(versionID)"
    }
}

extension WireCellsMessageAttachmentDraftEntityID: CustomDebugStringConvertible {
    public var debugDescription: String {
        "WireCellsMessageAttachmentDraftEntityID(uuid: \(uuid), versionID: \(versionID))"
    }
}

public struct WireCellsMessageAttachmentDraftEntity: Equatable, Hashable, Sendable {
    public let id: WireCellsMessageAttachmentDraftEntityID
    public let conversationId: WireCellsConversationID
    public let mimeType: String
    public let fileName: String
    public let fileSize: UInt64
    public let dataPath: String
    public let nodePath: String
    public let uploadStatus: String
    public let assetHeight: UInt64?
    public let assetWidth: UInt64?
    public let assetDuration: UInt64?

    package init(
        uuid: UUID,
        versionId: String,
        conversationId: WireCellsConversationID,
        mimeType: String,
        fileName: String,
        fileSize: UInt64,
        dataPath: String,
        nodePath: String,
        uploadStatus: String,
        assetHeight: UInt64?,
        assetWidth: UInt64?,
        assetDuration: UInt64?
    ) {
        self.id = WireCellsMessageAttachmentDraftEntityID(uuid: uuid, versionID: versionId)
        self.conversationId = conversationId
        self.mimeType = mimeType
        self.fileName = fileName
        self.fileSize = fileSize
        self.dataPath = dataPath
        self.nodePath = nodePath
        self.uploadStatus = uploadStatus
        self.assetHeight = assetHeight
        self.assetWidth = assetWidth
        self.assetDuration = assetDuration
    }
}
