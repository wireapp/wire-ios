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
import WireFoundation
import WireMessagingDomain

package class MessageAttachmentDraftDataSource: WireCellsMessageAttachmentDraftRepository {

    private let messageAttachmentDAO: any WireCellsMessageAttachmentDraftDAO

    init(messageAttachmentDAO: any WireCellsMessageAttachmentDraftDAO) {
        self.messageAttachmentDAO = messageAttachmentDAO
    }

    @discardableResult
    func add(
        conversationID: QualifiedID,
        node: WireCellsNode,
        versionID: UUID,
        mimeType: String,
        dataPath: String,
        metadata: WireCellsAssetMetadata?,
        uploadStatus: WireCellsAttachmentUploadStatus
    ) async throws(MessageAttachmentDraftRepositoryError) -> WireCellsMessageAttachmentDraft {
        do {
            return try await messageAttachmentDAO.addAttachment(
                uuid: .init(),
                versionID: versionID.uuidString,
                conversationID: conversationID,
                mimeType: mimeType,
                fileName: (node.path as NSString).lastPathComponent,
                fileSize: node.size ?? 0,
                dataPath: dataPath,
                nodePath: node.path,
                uploadStatus: uploadStatus,
                assetWidth: metadata?.width.map { UInt64($0) },
                assetHeight: metadata?.height.map { UInt64($0) },
                assetDuration: metadata?.durationMs.map { UInt64($0) }
            )
        } catch {
            throw .genericError(error)
        }
    }

    func observe(
        conversationID: QualifiedID
    ) async throws -> AsyncStream<[WireCellsMessageAttachmentDraft]> {
        try await messageAttachmentDAO.observeAttachments(
            conversationID: conversationID
        ).observe()
    }

    func updateStatus(
        draftID: WireCellsMessageAttachmentDraftID,
        status: WireCellsAttachmentUploadStatus
    ) async throws(MessageAttachmentDraftRepositoryError) {
        do {
            try await messageAttachmentDAO.updateUploadStatus(draftID: draftID, status: status)
        } catch {
            throw .genericError(error)
        }
    }

    func remove(draftID: WireCellsMessageAttachmentDraftID) async throws(MessageAttachmentDraftRepositoryError) {
        do {
            try await messageAttachmentDAO.deleteAttachment(draftID: draftID)
        } catch {
            throw .genericError(error)
        }
    }

    func removeAttachmentDrafts(conversationID: QualifiedID) async {
        do {
            try await messageAttachmentDAO.deleteAttachments(
                conversationID: conversationID
            )
        } catch {
            // Optionally log error
        }
    }

    func get(draftID: WireCellsMessageAttachmentDraftID) async throws(MessageAttachmentDraftRepositoryError)
        -> WireCellsMessageAttachmentDraft {
        do {
            if let attachment = try await messageAttachmentDAO.getAttachment(draftID: draftID) {
                return attachment
            } else {
                throw MessageAttachmentDraftRepositoryError.notFound
            }
        } catch let error as MessageAttachmentDraftRepositoryError {
            throw error
        } catch {
            throw .genericError(error)
        }
    }

    func getAll(conversationID: QualifiedID) async throws(MessageAttachmentDraftRepositoryError)
        -> [WireCellsMessageAttachmentDraft] {
        do {
            return try await messageAttachmentDAO.getAttachments(
                conversationID: conversationID
            )
        } catch {
            throw .genericError(error)
        }
    }
}
