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

public final class WireCellsMessageAttachmentDraftEntity: NSManagedObject {

    @NSManaged public var uuid: UUID
    @NSManaged public var versionID: String
    @NSManaged public var conversation: ZMConversation?
    @NSManaged public var mimeType: String
    @NSManaged public var fileName: String
    @NSManaged public var fileSize: UInt64
    @NSManaged public var dataPath: String
    @NSManaged public var nodePath: String
    @NSManaged public var uploadStatus: WireCellsAttachmentUploadStatus
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
            fileSize: fileSize,
            uploadStatus: uploadStatus,
            mimeType: mimeType,
            assetWidth: assetWidth?.uint64Value,
            assetHeight: assetHeight?.uint64Value,
            assetDuration: assetDuration?.uint64Value
        )
    }
}
