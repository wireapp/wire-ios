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

public enum MessageAttachmentDraftRepositoryError: Error, Sendable {
    case genericError(any Error)
    case notFound
}

public protocol WireDriveMessageAttachmentDraftRepository {

    @discardableResult
    func add(
        conversationID: QualifiedID,
        node: WireDriveNode,
        versionID: UUID,
        mimeType: String,
        dataPath: String,
        metadata: WireDriveAssetMetadata?,
        uploadStatus: WireDriveAttachmentUploadStatus
    ) async throws(MessageAttachmentDraftRepositoryError) -> WireDriveMessageAttachmentDraft

    func get(draftID: WireDriveMessageAttachmentDraftID) async throws(MessageAttachmentDraftRepositoryError)
        -> WireDriveMessageAttachmentDraft

    func getAll(conversationID: QualifiedID) async throws(MessageAttachmentDraftRepositoryError)
        -> [WireDriveMessageAttachmentDraft]

    func observe(conversationID: QualifiedID) async throws -> AsyncStream<[WireDriveMessageAttachmentDraft]>

    func updateStatus(
        draftID: WireDriveMessageAttachmentDraftID,
        status: WireDriveAttachmentUploadStatus
    ) async throws(MessageAttachmentDraftRepositoryError)

    func remove(draftID: WireDriveMessageAttachmentDraftID) async throws(MessageAttachmentDraftRepositoryError)

    func removeAttachmentDrafts(conversationID: QualifiedID) async
}
