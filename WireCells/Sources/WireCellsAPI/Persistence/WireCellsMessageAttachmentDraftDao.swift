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

public enum WireCellsMessageAttachmentDraftDaoError: Error {
    case attachmentNotFound
    case failedToDeleteAttachments
    case failedToCreateRequest
    case genericError(any Error)
}

public protocol FetchedResultsControllerObserver<T>: Actor where T: Sendable {
    associatedtype T
    func observe() -> AsyncStream<T>
}

// sourcery: AutoMockable
public protocol WireCellsMessageAttachmentDraftDao {

    associatedtype DraftsObserver: FetchedResultsControllerObserver<[WireCellsMessageAttachmentDraft]>

    func getAttachment(draftID: WireCellsMessageAttachmentDraftID) async throws(WireCellsMessageAttachmentDraftDaoError)
        -> WireCellsMessageAttachmentDraft?

    func getAttachments(conversationID: WireCellsConversationID) async throws(WireCellsMessageAttachmentDraftDaoError)
        -> [WireCellsMessageAttachmentDraft]

    func deleteAttachment(draftID: WireCellsMessageAttachmentDraftID) async throws(
        WireCellsMessageAttachmentDraftDaoError
    )

    func deleteAttachments(conversationID: WireCellsConversationID) async throws(
        WireCellsMessageAttachmentDraftDaoError
    )

    func observeAttachments(conversationID: WireCellsConversationID) async throws  -> DraftsObserver

    func addAttachment(
        uuid: UUID,
        versionID: String,
        conversationID: WireCellsConversationID,
        mimeType: String,
        fileName: String,
        fileSize: UInt64,
        dataPath: String,
        nodePath: String,
        uploadStatus: String,
        assetWidth: UInt64?,
        assetHeight: UInt64?,
        assetDuration: UInt64?
    ) async throws(WireCellsMessageAttachmentDraftDaoError) -> WireCellsMessageAttachmentDraft

    func updateUploadStatus(
        draftID: WireCellsMessageAttachmentDraftID,
        status: String
    ) async throws(WireCellsMessageAttachmentDraftDaoError)
}
