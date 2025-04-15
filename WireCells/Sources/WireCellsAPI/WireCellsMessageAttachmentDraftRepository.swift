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

import CellsSDK
import Foundation

public enum MessageAttachmentDraftRepositoryAddError: Error, Sendable {
    case genericError(any Error)
}

public enum MessageAttachmentDraftRepositoryGetError: Error, Sendable {
    case genericError(any Error)
    case notFound
}

public enum MessageAttachmentDraftRepositoryGetAllError: Error, Sendable {
    case genericError(any Error)
}

public enum MessageAttachmentDraftRepositoryUpdateStatusError: Error, Sendable {
    case genericError(any Error)
}

public enum MessageAttachmentDraftRepositoryRemoveError: Error, Sendable {
    case genericError(any Error)
}

public protocol WireCellsMessageAttachmentDraftRepository {

    @discardableResult
    func add(
        conversationID: WireCellsConversationID,
        node: WireCellsCellNode,
        mimeType: String,
        dataPath: String,
        metadata: WireCellsAssetMetadata?,
        uploadStatus: WireCellsAttachmentUploadStatus
    ) async throws(MessageAttachmentDraftRepositoryAddError) -> WireCellsAttachmentDraft

    func get(draftID: WireCellsAttachmentDraftID) async throws(MessageAttachmentDraftRepositoryGetError) -> WireCellsAttachmentDraft

    func getAll(conversationID: WireCellsConversationID) async throws(MessageAttachmentDraftRepositoryGetAllError) -> [WireCellsAttachmentDraft]


    func observe(conversationID: WireCellsConversationID) -> AnyAsyncSequence<[WireCellsAttachmentDraft], Never>

    func updateStatus(draftID: WireCellsAttachmentDraftID, status: WireCellsAttachmentUploadStatus) async throws(MessageAttachmentDraftRepositoryUpdateStatusError)

    func remove(draftID: WireCellsAttachmentDraftID) async throws(MessageAttachmentDraftRepositoryRemoveError)

    func removeAttachmentDrafts(conversationID: WireCellsConversationID) async
}
