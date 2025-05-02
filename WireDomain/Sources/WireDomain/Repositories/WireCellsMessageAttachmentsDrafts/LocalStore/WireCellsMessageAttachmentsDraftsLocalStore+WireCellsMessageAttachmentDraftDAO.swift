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

// Preconcurrency macro to allow for injecting the NSFetchedResultsController
@preconcurrency import CoreData
import Foundation
import WireCellsAPI
import WireDataModel

extension WireCellsMessageAttachmentsDraftsLocalStore: WireCellsMessageAttachmentDraftDAO {

    public func getAttachment(draftID: WireCellsMessageAttachmentDraftID) async throws(
        WireCellsMessageAttachmentDraftDAOError
    ) -> WireCellsMessageAttachmentDraft? {
        do {
            return try await context.perform { [context] in
                guard let fetchRequest = Self.attachmentFetchRequest(for: draftID) else {
                    throw WireCellsMessageAttachmentDraftDAOError.failedToCreateRequest
                }

                guard let entity = (try context.fetch(fetchRequest)).first else {
                    return nil
                }
                return entity.toModel()
            }
        } catch {
            throw .genericError(error)
        }
    }

    public func getAttachments(conversationID: WireCellsConversationID) async throws(
        WireCellsMessageAttachmentDraftDAOError
    ) -> [WireCellsMessageAttachmentDraft] {
        do {
            return try await context.perform { [context] in
                guard let fetchRequest = Self.attachmentsFetchRequest(for: conversationID) else {
                    throw WireCellsMessageAttachmentDraftDAOError.failedToCreateRequest
                }

                let entities = try context.fetch(fetchRequest)

                return entities.map { $0.toModel() }
            }
        } catch {
            throw .genericError(error)
        }
    }

    public func deleteAttachment(draftID: WireCellsMessageAttachmentDraftID) async throws(
        WireCellsMessageAttachmentDraftDAOError
    ) {
        do {
            return try await context.perform { [context] in
                guard let fetchRequest = Self.attachmentFetchRequest(for: draftID) else {
                    throw WireCellsMessageAttachmentDraftDAOError.failedToCreateRequest
                }
                guard let entity = (try context.fetch(fetchRequest)).first else {
                    return
                }
                context.delete(entity)
                try context.save()
            }
        } catch {
            throw .genericError(error)
        }
    }

    public func deleteAttachments(conversationID: WireCellsConversationID) async throws(
        WireCellsMessageAttachmentDraftDAOError
    ) {
        do {
            return try await context.perform { [context] in
                guard let fetchRequest = Self
                    .attachmentsFetchRequest(for: conversationID) as? NSFetchRequest<any NSFetchRequestResult> else {
                    throw WireCellsMessageAttachmentDraftDAOError.failedToCreateRequest
                }

                let batchRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                batchRequest.resultType = .resultTypeStatusOnly

                let result = try context.execute(batchRequest) as? NSBatchDeleteResult

                if result?.result as? Bool == false {
                    throw WireCellsMessageAttachmentDraftDAOError.failedToDeleteAttachments
                }
            }
        } catch {
            throw .genericError(error)
        }
    }

    // Observes the attachment list for a conversation.
    // Emits the current attachment list for `conversationID` and every time it
    // changes thereafter.  When the caller drops the `AsyncStream`, the delegate
    // is released automatically.
    public func observeAttachments(
        conversationID: WireCellsConversationID
    ) async throws -> WireCellsMessageAttachmentDraftsObserverImplementation {
        let request = NSFetchRequest<WireCellsMessageAttachmentDraftEntity>(
            entityName: "WireCellsMessageAttachmentDraftEntity"
        )
        request.predicate = NSPredicate(
            format: "conversation.uuid == %@ AND conversation.domain == %@",
            conversationID.uuid.uuidString,
            conversationID.domain
        )

        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        let initialValues = try await context.perform {
            try fetchedResultsController.performFetch()
            if let start = fetchedResultsController.fetchedObjects {
                return start.map { $0.toModel() }
            }
            return []
        }

        return try await WireCellsMessageAttachmentDraftsObserverImplementation(
            fetchedResultsController: fetchedResultsController,
            initialValues: initialValues
        )
    }

    public func addAttachment(
        uuid: UUID,
        versionID: String,
        conversationID: WireCellsConversationID,
        mimeType: String,
        fileName: String,
        fileSize: UInt64,
        dataPath: String,
        nodePath: String,
        uploadStatus: WireCellsAttachmentUploadStatus,
        assetWidth: UInt64?,
        assetHeight: UInt64?,
        assetDuration: UInt64?
    ) async throws(WireCellsMessageAttachmentDraftDAOError) -> WireCellsMessageAttachmentDraft {
        do {
            let conversation = await conversationStore.fetchConversation(
                id: conversationID.uuid,
                domain: conversationID.domain
            )
            return try await context.perform { [context] in
                let entity = WireCellsMessageAttachmentDraftEntity()
                entity.uuid = uuid
                entity.versionID = versionID
                entity.conversation = conversation
                entity.mimeType = mimeType
                entity.fileName = fileName
                entity.fileSize = Int64(fileSize)
                entity.dataPath = dataPath
                entity.nodePath = nodePath
                entity.uploadStatus = .init(uploadStatus)
                entity.assetWidth = assetWidth.map(NSNumber.init)
                entity.assetHeight = assetHeight.map(NSNumber.init)
                entity.assetDuration = assetDuration.map(NSNumber.init)

                try context.save()

                return entity.toModel()
            }
        } catch {
            throw .genericError(error)
        }
    }

    public func updateUploadStatus(
        draftID: WireCellsMessageAttachmentDraftID,
        status: WireCellsAttachmentUploadStatus
    ) async throws(WireCellsMessageAttachmentDraftDAOError) {
        do {
            return try await context.perform { [context] in
                guard let fetchRequest = Self.attachmentFetchRequest(for: draftID) else {
                    throw WireCellsMessageAttachmentDraftDAOError.failedToCreateRequest
                }
                guard let entity = (try context.fetch(fetchRequest)).first else {
                    throw WireCellsMessageAttachmentDraftDAOError.attachmentNotFound
                }
                entity.uploadStatus = .init(status)
                try context.save()
            }
        } catch let error as WireCellsMessageAttachmentDraftDAOError {
            throw error
        } catch {
            throw .genericError(error)
        }
    }

    private static func attachmentFetchRequest(for draftID: WireCellsMessageAttachmentDraftID)
        -> NSFetchRequest<WireCellsMessageAttachmentDraftEntity>? {
        guard let fetchRequest =
            WireCellsMessageAttachmentDraftEntity
                .fetchRequest() as? NSFetchRequest<WireCellsMessageAttachmentDraftEntity> else {
            return nil
        }

        let uuidPredicate = NSPredicate(format: "uuid == %@", draftID.uuid.uuidString)
        let versionIDPredicate = NSPredicate(format: "versionID == %@", draftID.versionID)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [uuidPredicate, versionIDPredicate])

        fetchRequest.predicate = predicate
        fetchRequest.fetchLimit = 1
        fetchRequest.returnsObjectsAsFaults = false

        return fetchRequest
    }

    private static func attachmentsFetchRequest(for conversationID: WireCellsConversationID)
        -> NSFetchRequest<WireCellsMessageAttachmentDraftEntity>? {
        guard let fetchRequest =
            WireCellsMessageAttachmentDraftEntity
                .fetchRequest() as? NSFetchRequest<WireCellsMessageAttachmentDraftEntity> else {
            return nil
        }

        let predicate = NSPredicate(
            format: "conversation.teamRemoteIdentifier == %@ AND conversation.domain == %@",
            conversationID.uuid.uuidString,
            conversationID.domain
        )

        fetchRequest.predicate = predicate
        fetchRequest.fetchBatchSize = 100

        return fetchRequest
    }
}

// MARK: - FRC → AsyncStream bridge

private final class FRCDelegate<Entity: NSManagedObject>:
    NSObject, NSFetchedResultsControllerDelegate {
    private let onChange: ([Entity]) -> Void
    init(onChange: @escaping ([Entity]) -> Void) { self.onChange = onChange }

    func controllerDidChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {
        guard let entities = controller.fetchedObjects as? [Entity] else { return }
        onChange(entities)
    }
}
