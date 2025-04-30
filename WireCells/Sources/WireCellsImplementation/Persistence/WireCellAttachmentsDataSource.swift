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
import WireCellsAPI

package class MessageAttachmentDraftDataSource: WireCellsMessageAttachmentDraftRepository {

    private let messageAttachmentDao: any WireCellsMessageAttachmentDraftDao

    init(messageAttachmentDao: any WireCellsMessageAttachmentDraftDao) {
        self.messageAttachmentDao = messageAttachmentDao
    }

    @discardableResult
    func add(
        conversationID: WireCellsConversationID,
        node: WireCellsCellNode,
        mimeType: String,
        dataPath: String,
        metadata: WireCellsAssetMetadata?,
        uploadStatus: WireCellsAttachmentUploadStatus
    ) async throws(MessageAttachmentDraftRepositoryError) -> WireCellsMessageAttachmentDraft {
        fatalError()
        // FIXME: Fix and uncomment
//        do {
//            return try await messageAttachmentDao.addAttachment(
//                uuid: node.id.uuid,
//                versionID: node.id.versionID,
//                conversationID: conversationID,
//                mimeType: mimeType,
//                fileName: (node.path as NSString).lastPathComponent,
//                fileSize: node.size ?? 0,
//                dataPath: dataPath,
//                nodePath: node.path,
//                status: uploadStatus.rawValue,
//                assetWidth: metadata?.width,
//                assetHeight: metadata?.height,
//                assetDuration: metadata?.durationMs
//            )
//        } catch {
//            throw .genericError(error)
//        }
    }

    func observe(
        conversationID: WireCellsConversationID
    )-> AsyncStream<[WireCellsMessageAttachmentDraft]> {
        fatalError()
        // FIXME: Fix and uncomment
//        messageAttachmentDao.observeAttachments(
//            conversationID: conversationID
//        )
    }

    func updateStatus(
        draftID: WireCellsMessageAttachmentDraftID,
        status: WireCellsAttachmentUploadStatus
    ) async throws(MessageAttachmentDraftRepositoryError) {
        do {
            try await messageAttachmentDao.updateUploadStatus(draftID: draftID, status: status.rawValue)
        } catch {
            throw .genericError(error)
        }
    }

    func remove(draftID: WireCellsMessageAttachmentDraftID) async throws(MessageAttachmentDraftRepositoryError) {
        do {
            try await messageAttachmentDao.deleteAttachment(draftID: draftID)
        } catch {
            throw .genericError(error)
        }
    }

    func removeAttachmentDrafts(conversationID: WireCellsConversationID) async {
        do {
            try await messageAttachmentDao.deleteAttachments(
                conversationID: conversationID
            )
        } catch {
            // Optionally log error
        }
    }

    func get(draftID: WireCellsMessageAttachmentDraftID) async throws(MessageAttachmentDraftRepositoryError)
        -> WireCellsMessageAttachmentDraft {
        do {
            if let attachment = try await messageAttachmentDao.getAttachment(draftID: draftID) {
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

    func getAll(conversationID: WireCellsConversationID) async throws(MessageAttachmentDraftRepositoryError)
        -> [WireCellsMessageAttachmentDraft] {
        do {
            return try await messageAttachmentDao.getAttachments(
                conversationID: conversationID
            )
        } catch {
            throw .genericError(error)
        }
    }
}

// fileprivate func withCheckedThrowingContinuation<T, Failure: Error>(
//    dispatchQueue: DispatchQueue,
//    isolation: isolated (any Actor)? = #isolation,
//    function: String = #function,
//    _ body: @escaping @Sendable () throws(Failure) -> T
// ) async throws -> sending T {
//    try await withCheckedThrowingContinuation(isolation: isolation, function: function) { continuation in
//        dispatchQueue.async {
//            do {
//                continuation.resume(returning: try body())
//            } catch {
//                continuation.resume(throwing: error)
//            }
//        }
//    }
// }
