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

public import Foundation
public import WireFoundation

public enum WireDriveMessageAttachmentDraftDAOError: Error {
    case attachmentNotFound
    case failedToDeleteAttachments
    case failedToCreateRequest
    case genericError(any Error)
}

public protocol FetchedResultsControllerObserver<T>: Actor where T: Sendable {
    associatedtype T
    func observe() -> AsyncStream<T>
}

public protocol WireDriveMessageAttachmentDraftDAO {

    associatedtype DraftsObserver: FetchedResultsControllerObserver<[WireDriveMessageAttachmentDraft]>

    func getAttachment(draftID: WireDriveMessageAttachmentDraftID) async throws(WireDriveMessageAttachmentDraftDAOError)
        -> WireDriveMessageAttachmentDraft?

    func getAttachments(conversationID: QualifiedID) async throws(WireDriveMessageAttachmentDraftDAOError)
        -> [WireDriveMessageAttachmentDraft]

    func deleteAttachment(draftID: WireDriveMessageAttachmentDraftID) async throws(
        WireDriveMessageAttachmentDraftDAOError
    )

    func deleteAttachments(conversationID: QualifiedID) async throws(
        WireDriveMessageAttachmentDraftDAOError
    )

    func observeAttachments(conversationID: QualifiedID) async throws -> DraftsObserver

    func addAttachment(
        uuid: UUID,
        versionID: String,
        conversationID: QualifiedID,
        mimeType: String,
        fileName: String,
        fileSize: UInt64,
        dataPath: String,
        nodePath: String,
        uploadStatus: WireDriveAttachmentUploadStatus,
        assetWidth: UInt64?,
        assetHeight: UInt64?,
        assetDuration: UInt64?
    ) async throws(WireDriveMessageAttachmentDraftDAOError) -> WireDriveMessageAttachmentDraft

    func updateUploadStatus(
        draftID: WireDriveMessageAttachmentDraftID,
        status: WireDriveAttachmentUploadStatus
    ) async throws(WireDriveMessageAttachmentDraftDAOError)
}
