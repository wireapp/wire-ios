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
    // This queue is used to synchronize access to the database.
    // And ensure all database operations are performed on the same queue.
    private let dispatchQueue: DispatchQueue


    init(
        messageAttachmentDao: any WireCellsMessageAttachmentDraftDao,
        dispatchQueue: DispatchQueue
    ) {
        self.messageAttachmentDao = messageAttachmentDao
        self.dispatchQueue = dispatchQueue
    }

    @discardableResult
    func add(
        conversationID: WireCellsConversationID,
        node: WireCellsCellNode,
        mimeType: String,
        dataPath: String,
        metadata: WireCellsAssetMetadata?,
        uploadStatus: WireCellsAttachmentUploadStatus
    ) async throws(MessageAttachmentDraftRepositoryAddError) -> WireCellsAttachmentDraft {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                dispatchQueue.async { [messageAttachmentDao] in
                    do {
                        let entity = try messageAttachmentDao.addAttachment(
                            uuid: node.id.uuid,
                            versionID: node.id.versionID,
                            conversationID: conversationID.qualifiedID,
                            mimeType: mimeType,
                            fileName: (node.path as NSString).lastPathComponent,
                            fileSize: node.size ?? 0,
                            dataPath: dataPath,
                            nodePath: node.path,
                            status: uploadStatus.rawValue,
                            assetWidth: metadata?.width,
                            assetHeight: metadata?.height,
                            assetDuration: metadata?.durationMs
                        )
                        continuation.resume(returning: entity.toModel())
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            if let error = error as? MessageAttachmentDraftRepositoryAddError {
                throw error
            } else {
                throw MessageAttachmentDraftRepositoryAddError.genericError(error)
            }
        }
    }

    func observe(conversationID: WireCellsConversationID) -> AnyAsyncSequence<[WireCellsAttachmentDraft], Never> {
        let mappedSequence = messageAttachmentDao.observeAttachments(
            conversationID: conversationID.qualifiedID
        ).map { entityList in
            entityList.map { $0.toModel() }
        }
        return AnyAsyncSequence(mappedSequence)
    }

    func updateStatus(draftID: WireCellsAttachmentDraftID, status: WireCellsAttachmentUploadStatus) async throws(MessageAttachmentDraftRepositoryUpdateStatusError) {

        do {
            try await withCheckedThrowingContinuation { continuation in
                dispatchQueue.async { [messageAttachmentDao] in
                    do {
                        try messageAttachmentDao.updateUploadStatus(draftID: draftID, status: status.rawValue)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            if let error = error as? MessageAttachmentDraftRepositoryUpdateStatusError {
                throw error
            } else {
                throw MessageAttachmentDraftRepositoryUpdateStatusError.genericError(error)
            }
        }
    }

    func remove(draftID: WireCellsAttachmentDraftID) async throws(MessageAttachmentDraftRepositoryRemoveError) -> Void {
        do {
            try await withCheckedThrowingContinuation { continuation in
                dispatchQueue.async { [messageAttachmentDao] in
                    do {
                        try messageAttachmentDao.deleteAttachment(draftID: draftID)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            if let error = error as? MessageAttachmentDraftRepositoryRemoveError {
                throw error
            } else {
                throw MessageAttachmentDraftRepositoryRemoveError.genericError(error)
            }
        }
    }

    func removeAttachmentDrafts(conversationID: WireCellsConversationID) async {
        do {
            try await withCheckedThrowingContinuation { continuation in
                dispatchQueue.async { [messageAttachmentDao] in
                    do {
                        try messageAttachmentDao.deleteAttachments(
                            conversationID: conversationID.qualifiedID
                        )
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            // Optionally log error
        }
    }

    func get(draftID: WireCellsAttachmentDraftID) async throws(MessageAttachmentDraftRepositoryGetError) -> WireCellsAttachmentDraft {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                dispatchQueue.async { [messageAttachmentDao] in
                    do {
                        if let entity = try messageAttachmentDao.getAttachment(draftID: draftID) {
                            continuation.resume(returning: entity.toModel())
                        } else {
                            continuation.resume(throwing: MessageAttachmentDraftRepositoryGetError.notFound)
                        }
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            if let error = error as? MessageAttachmentDraftRepositoryGetError {
                throw error
            } else {
                throw MessageAttachmentDraftRepositoryGetError.genericError(error)
            }
        }
    }

    func getAll(conversationID: WireCellsConversationID) async throws(MessageAttachmentDraftRepositoryGetAllError) -> [WireCellsAttachmentDraft] {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                dispatchQueue.async { [messageAttachmentDao] in
                    do {
                        let entities = try messageAttachmentDao.getAttachments(
                            conversationID: conversationID.qualifiedID
                        )
                        continuation.resume(returning: entities.map { $0.toModel() })
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            if let error = error as? MessageAttachmentDraftRepositoryGetAllError {
                throw error
            } else {
                throw MessageAttachmentDraftRepositoryGetAllError.genericError(error)
            }
        }
    }
}

//fileprivate func withCheckedThrowingContinuation<T, Failure: Error>(
//    dispatchQueue: DispatchQueue,
//    isolation: isolated (any Actor)? = #isolation,
//    function: String = #function,
//    _ body: @escaping @Sendable () throws(Failure) -> T
//) async throws -> sending T {
//    try await withCheckedThrowingContinuation(isolation: isolation, function: function) { continuation in
//        dispatchQueue.async {
//            do {
//                continuation.resume(returning: try body())
//            } catch {
//                continuation.resume(throwing: error)
//            }
//        }
//    }
//}

extension WireCellsMessageAttachmentDraftEntity {
    func toModel() -> WireCellsAttachmentDraft {
        return WireCellsAttachmentDraft(
            uuid: id.uuid,
            versionID: id.versionID,
            fileName: fileName,
            remoteFilePath: nodePath,
            localFilePath: dataPath,
            fileSize: fileSize,
            uploadStatus: WireCellsAttachmentUploadStatus(rawValue: uploadStatus) ?? .uploading,
            mimeType: mimeType,
            assetWidth: assetWidth,
            assetHeight: assetHeight,
            assetDuration: assetDuration
        )
    }
}
