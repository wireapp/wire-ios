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

package import Foundation

public struct WireCellsAttachmentDraftID: Equatable, Hashable, Identifiable, Sendable {
    package let uuid: UUID
    package let versionID: String

    public var id: String {
        "\(uuid.uuidString)/\(versionID)"
    }

    package init(uuid: UUID, versionID: String) {
        self.uuid = uuid
        self.versionID = versionID
    }
}

extension WireCellsAttachmentDraftID: CustomStringConvertible {
    public var description: String {
        "\(uuid.uuidString)/\(versionID)"
    }
}

extension WireCellsAttachmentDraftID: CustomDebugStringConvertible {
    public var debugDescription: String {
        "WireCellsAttachmentDraftID(uuid: \(uuid), versionID: \(versionID))"
    }
}

public struct WireCellsAttachmentDraft: Sendable, Hashable, Identifiable {
    public let id: WireCellsAttachmentDraftID
    public let fileName: String
    public let remoteFilePath: String
    public let localFilePath: String
    public let fileSize: UInt64
    public let uploadStatus: WireCellsAttachmentUploadStatus
    public let mimeType: String
    public let assetWidth: UInt64?
    public let assetHeight: UInt64?
    public let assetDuration: UInt64?

    package init(
        uuid: UUID,
        versionID: String,
        fileName: String,
        remoteFilePath: String,
        localFilePath: String,
        fileSize: UInt64,
        uploadStatus: WireCellsAttachmentUploadStatus,
        mimeType: String,
        assetWidth: UInt64?,
        assetHeight: UInt64?,
        assetDuration: UInt64?
    ) {
        self.id = WireCellsAttachmentDraftID(
            uuid: uuid,
            versionID: versionID
        )
        self.fileName = fileName
        self.remoteFilePath = remoteFilePath
        self.localFilePath = localFilePath
        self.fileSize = fileSize
        self.uploadStatus = uploadStatus
        self.mimeType = mimeType
        self.assetWidth = assetWidth
        self.assetHeight = assetHeight
        self.assetDuration = assetDuration
    }
}

public enum WireCellsAttachmentUploadStatus: String, Sendable, Hashable {
    case uploading
    case uploaded
    case failed
}
