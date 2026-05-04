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

@objc
public enum WireCellsMessageAttachmentDraftUploadStatus: Int16 {
    case uploading = 0
    case uploaded = 1
    case failed = 2
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
}
