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
public import WireCellsAPI

@objc
public enum WireCellsMessageAttachmentDraftUploadStatus: Int16 {
    case uploading = 0
    case uploaded = 1
    case failed = 2

    public init(_ value: WireCellsAttachmentUploadStatus) {
        switch value {
        case .uploading:
            self = .uploading
        case .uploaded:
            self = .uploaded
        case .failed:
            self = .failed
        }
    }

    public func toModel() -> WireCellsAttachmentUploadStatus {
        switch self {
        case .uploading:
            .uploading
        case .uploaded:
            .uploaded
        case .failed:
            .failed
        }
    }
}

@objc
public final class WireCellsMessageAttachmentDraftEntity: NSManagedObject {

    @NSManaged public var uuid: UUID
    @NSManaged public var versionID: String
    @NSManaged public var conversation: ZMConversation?
    @NSManaged public var mimeType: String
    @NSManaged public var fileName: String
    @NSManaged public var fileSize: Int64
    @NSManaged public var dataPath: String
    @NSManaged public var nodePath: String
    @NSManaged public var uploadStatus: WireCellsMessageAttachmentDraftUploadStatus
    @NSManaged public var assetHeight: NSNumber?
    @NSManaged public var assetWidth: NSNumber?
    @NSManaged public var assetDuration: NSNumber?

    public func toModel() -> WireCellsMessageAttachmentDraft {
        WireCellsMessageAttachmentDraft(
            uuid: uuid,
            versionID: versionID,
            fileName: fileName,
            remoteFilePath: nodePath,
            localFilePath: dataPath,
            fileSize: UInt64(fileSize),
            uploadStatus: uploadStatus.toModel(),
            mimeType: mimeType,
            assetWidth: assetWidth?.uint64Value,
            assetHeight: assetHeight?.uint64Value,
            assetDuration: assetDuration?.uint64Value
        )
    }
}
