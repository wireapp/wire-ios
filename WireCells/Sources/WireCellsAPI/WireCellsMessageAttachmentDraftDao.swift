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

public protocol WireCellsMessageAttachmentDraftDao: Sendable {
    func getAttachment(draftID: WireCellsAttachmentDraftID) throws -> WireCellsMessageAttachmentDraftEntity?

    func getAttachments(conversationID: WireCellsQualifiedID) throws -> [WireCellsMessageAttachmentDraftEntity]

    func deleteAttachment(draftID: WireCellsAttachmentDraftID) throws

    func deleteAttachments(conversationID: WireCellsQualifiedID) throws

    func observeAttachments(conversationID: WireCellsQualifiedID) -> AsyncStream<[WireCellsMessageAttachmentDraftEntity]>

    func addAttachment(
        uuid: UUID,
        versionID: String,
        conversationID: WireCellsQualifiedID,
        mimeType: String,
        fileName: String,
        fileSize: Int64,
        dataPath: String,
        nodePath: String,
        status: String,
        assetWidth: Int?,
        assetHeight: Int?,
        assetDuration: Int64?
    ) throws -> WireCellsMessageAttachmentDraftEntity

    func updateUploadStatus(draftID: WireCellsAttachmentDraftID, status: String) throws
}
