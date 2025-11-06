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

import GenericMessageProtocol
import WireBackup
import WireDataModel
import WireFoundation
import WireLogging
import WireNetwork

// MARK: - Interface

extension BackupLocalStore {

    func refreshViewContext() async throws {
        await contextProvider.viewContext.perform { [context = contextProvider.viewContext] in
            context.refreshAllObjects()
        }
    }

    func fetchAllMessageIDs() async throws -> Set<String> {
        try await backupContext.perform { [backupContext] in
            let fetchRequest = ZMMessage.fetchRequest()
            fetchRequest.propertiesToFetch = ["nonce_data"]

            let messages = try backupContext.fetch(fetchRequest) as! [ZMMessage]
            return Set(messages.compactMap(\.nonce).map(\.uuidString))
        }
    }

    func fetchAllMessages() -> AsyncThrowingStream<MessageBackupModel, any Error> {
        AsyncThrowingStream { continuation in
            Task<Void, Never> {
                do {
                    try await backupContext.perform {
                        let messages = try backupContext.fetch(messageFetchRequest) as! [ZMMessage]
                        for message in messages {
                            autoreleasepool {
                                if let backupMessage = MessageBackupModel(message) {
                                    continuation.yield(backupMessage)
                                }
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - Restoring messages

extension BackupLocalStore {

    // MARK: Private types

    private typealias CoreDataAttributes = [String: Any]
    private typealias QualifiedID = WireFoundation.QualifiedID
    private typealias ImportResult = BackupMessagesImportResult

    private struct RehydrationData {
        let senderID: QualifiedID
        let conversationID: QualifiedID
        let genericMessage: GenericMessage
    }

    private struct MessagesImportData {
        let conversationDomains: Set<String>
        let conversationIdsData: Set<Data>
        let senderDomains: Set<String>
        let senderIdsData: Set<Data>
        let rehydrationDataByNonce: [UUID: RehydrationData]
        let clientMessagesAttributes: [CoreDataAttributes]
        let assetMessagesAttributes: [CoreDataAttributes]
    }

    func addMessages(_ backupMessages: [MessageBackupModel]) async throws -> BackupMessagesImportResult {
        logPublic("Starting import of \(backupMessages.count) messages")

        // Validate and collect import data
        let (importData, validationResult) = validateAndCollectMessagesImportData(from: backupMessages)
        logPublic("Validation: \(validationResult.successCount) valid, \(validationResult.failureCount) invalid")

        // Fetch relationships
        let (sendersByID, conversationsByID) = try await fetchRelationships(from: importData)
        logPublic("Fetched \(sendersByID.count) senders, \(conversationsByID.count) conversations")

        // Insert messages
        let (insertedIDs, insertionResult) = await batchInsertMessages(
            clientMessagesAttributes: importData.clientMessagesAttributes,
            assetMessagesAttributes: importData.assetMessagesAttributes
        )
        logPublic("Insertion: \(insertionResult.successCount) succeeded, \(insertionResult.failureCount) failed")

        // Rehydrate messages (set relationships and generic message)
        let rehydrationResult = try await rehydrateAllMessages(
            insertedIDs: insertedIDs,
            sendersByID: sendersByID,
            conversationsByID: conversationsByID,
            rehydrationDataByNonce: importData.rehydrationDataByNonce
        )
        logPublic("Rehydration: \(rehydrationResult.successCount) succeeded, \(rehydrationResult.failureCount) failed")

        try await backupContext.perform {
            // Save context
            try backupContext.save()
            // Reset context - frees up memory for the next batch
            backupContext.reset()
        }

        logPublic("Import completed")

        return ImportResult(
            validationCount: validationResult,
            insertionCount: insertionResult,
            rehydrationCount: rehydrationResult
        )
    }

    private func logPublic(_ message: String) {
        WireLogger.backupImport.info(
            "\(message)",
            attributes: .safePublic
        )
    }

    // MARK: Collecting data for import

    /// Validates backup messages content and collects data needed to fetch relationships in batches
    /// as well as messages data for batch inserts and rehydration - in a single-pass loop for performance
    ///
    /// - Parameter backupMessages: The backup messages from the backup file
    /// - Returns: A tuple of message data and validation result

    private func validateAndCollectMessagesImportData(
        from backupMessages: [MessageBackupModel]
    ) -> (importData: MessagesImportData, validationResult: ImportResult.ResultCount) {

        // Conversations domains and UUIDs for batch fetch
        var conversationDomains = Set<String>()
        var conversationIdsData = Set<Data>()

        // Senders domains and UUIDs for batch fetch
        var senderDomains = Set<String>()
        var senderIdsData = Set<Data>()

        // Dictionary to map messages to conversations, senders, and
        // generic messages to restore after insert
        var rehydrationDataByNonce: [UUID: RehydrationData] = [:]

        // The attributes from messages for batch insert
        var clientMessagesAttributes: [CoreDataAttributes] = []
        var assetMessagesAttributes: [CoreDataAttributes] = []

        var invalidCount = 0

        for message in backupMessages {

            // Validate message
            guard
                let nonce = UUID(transportString: message.id),
                let genericMessage = GenericMessage(nonce: nonce, messageContent: message.content),
                genericMessage.validateFields()
            else {
                invalidCount += 1
                continue
            }

            // Build Core Data attributes and categorize messages
            if message.content.isAsset {
                let attributes = buildCoreDataAttributes(for: message, nonce: nonce)
                assetMessagesAttributes.append(attributes)
            } else if message.content.isText || message.content.isLocation {
                let attributes = buildCoreDataAttributes(for: message, nonce: nonce)
                clientMessagesAttributes.append(attributes)
            } else {
                invalidCount += 1
                continue
            }

            // Build mapping to set generic messages, senders and conversations after insert
            rehydrationDataByNonce[nonce] = RehydrationData(
                senderID: message.senderUserID,
                conversationID: message.conversationID,
                genericMessage: genericMessage
            )

            // Collect IDs to fetch relationship objects batches, to set after insert
            conversationIdsData.insert(message.conversationID.id.uuidData)
            conversationDomains.insert(message.conversationID.domain)
            senderIdsData.insert(message.senderUserID.id.uuidData)
            senderDomains.insert(message.senderUserID.domain)
        }

        return (
            importData: MessagesImportData(
                conversationDomains: conversationDomains,
                conversationIdsData: conversationIdsData,
                senderDomains: senderDomains,
                senderIdsData: senderIdsData,
                rehydrationDataByNonce: rehydrationDataByNonce,
                clientMessagesAttributes: clientMessagesAttributes,
                assetMessagesAttributes: assetMessagesAttributes
            ),
            validationResult: .init(
                successCount: backupMessages.count - invalidCount,
                failureCount: invalidCount
            )
        )
    }

    private func buildCoreDataAttributes(
        for message: MessageBackupModel,
        nonce: UUID
    ) -> CoreDataAttributes {
        var attributes: CoreDataAttributes = [
            ZMMessageNonceDataKey: nonce.uuidData,
            #keyPath(ZMOTRMessage.serverTimestamp): message.creationDate
        ]

        if let senderClientID = message.senderClientID {
            attributes[#keyPath(ZMOTRMessage.senderClientID)] = senderClientID
        }

        return attributes
    }

    // MARK: Fetching relationships

    /// Fetches senders and conversations needed to re-establish relationships with messages.
    /// Parallelized in batches.
    /// - Parameter importData: The data containing conversations and senders uuids data and domains
    /// - Returns: a tuple of dictionaries: senders by qualified ID and conversations by qualified ID

    private func fetchRelationships(
        from importData: MessagesImportData
    ) async throws -> (
        sendersByID: [QualifiedID: ZMUser],
        conversationsByID: [QualifiedID: ZMConversation]
    ) {

        async let sendersByID = fetchQualifiedObjects(
            uuidsData: importData.senderIdsData,
            domains: importData.senderDomains,
            context: backupContext
        ) as [QualifiedID: ZMUser]

        async let conversationsByID = fetchQualifiedObjects(
            uuidsData: importData.conversationIdsData,
            domains: importData.conversationDomains,
            context: backupContext
        ) as [QualifiedID: ZMConversation]

        return try await (sendersByID, conversationsByID)
    }

    private func fetchQualifiedObjects<T: ZMManagedObject & HasQualifiedID>(
        uuidsData: Set<Data>,
        domains: Set<String>,
        context: NSManagedObjectContext
    ) async throws -> [QualifiedID: T] {

        do {
            return try await context.perform {
                let fetchRequest = T.fetchRequest()

                let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "%K IN %@", T.remoteIdentifierDataKey(), uuidsData),
                    NSPredicate(format: "%K IN %@", T.domainKey(), domains)
                ])

                fetchRequest.predicate = predicate

                let fetchResult = try context.fetch(fetchRequest) as! [T]

                return [QualifiedID: T](uniqueKeysWithValues: fetchResult.compactMap {
                    guard let qualifiedID = $0.qualifiedID?.toFoundationQualifiedID() else { return nil }

                    return (qualifiedID, $0)
                })
            }
        } catch {
            WireLogger.backupImport.warn("Failed to fetch qualified objects: \(String(describing: error))")
            throw BackupMessagesImportFailure.failedToFetchRelationships
        }
    }

    // MARK: Inserting batches

    /// Inserts asset messages and client messages in batches, directly into the SQLite db.
    ///
    /// - Parameters:
    ///   - clientMessagesAttributes: an array of core data attributes to insert for client messages
    ///   - assetMessagesAttributes: an array of core data attributes to insert for asset messages
    /// - Returns: a tuple containing the inserted objects objectIDs and the insertion result count

    private func batchInsertMessages(
        clientMessagesAttributes: [CoreDataAttributes],
        assetMessagesAttributes: [CoreDataAttributes]
    ) async -> (insertedIDs: [NSManagedObjectID], insertionResult: ImportResult.ResultCount) {

        var insertedMessagesIDs: [NSManagedObjectID] = []

        do {
            insertedMessagesIDs += try await batchInsert(
                attributes: clientMessagesAttributes,
                entityDescription: clientMessageEntityDescription,
                context: backupContext
            )
        } catch {
            WireLogger.backupImport.warn("Failed to insert client messages batch: \(String(describing: error))")
        }

        do {
            insertedMessagesIDs += try await batchInsert(
                attributes: assetMessagesAttributes,
                entityDescription: assetMessageEntityDescription,
                context: backupContext
            )
        } catch {
            WireLogger.backupImport.warn("Failed to insert asset messages batch: \(String(describing: error))")
        }

        let toInsertCount = assetMessagesAttributes.count + clientMessagesAttributes.count
        let insertedCount = insertedMessagesIDs.count

        return (
            insertedIDs: insertedMessagesIDs,
            insertionResult: .init(
                successCount: insertedCount,
                failureCount: toInsertCount - insertedCount
            )
        )
    }

    private enum BatchInsertFailure: Error {
        case failedToInsertBatch(error: Error, entity: String)
        case failedToGetEntityDescription
    }

    private func batchInsert(
        attributes: [CoreDataAttributes],
        entityDescription: NSEntityDescription?,
        context: NSManagedObjectContext
    ) async throws -> [NSManagedObjectID] {
        guard !attributes.isEmpty else { return [] }

        guard let entityDescription else {
            throw BatchInsertFailure.failedToGetEntityDescription
        }

        let insertRequest = NSBatchInsertRequest(
            entity: entityDescription,
            objects: attributes
        )
        insertRequest.resultType = .objectIDs

        do {
            let insertResult = try await context.perform {
                try context.execute(insertRequest) as? NSBatchInsertResult
            }

            return insertResult?.result as? [NSManagedObjectID] ?? []
        } catch {
            throw BatchInsertFailure.failedToInsertBatch(
                error: error,
                entity: entityDescription.name ?? "unknown"
            )
        }
    }

    // MARK: Rehydrating messages

    /// Restores messages relationships with senders and conversations,
    /// sets the underlying generic message data, and marks the message as read.
    ///
    /// If any messages failed rehydration, we remove them in a single batch, to avoid zombie objects in DB.
    ///
    /// - Parameters:
    ///   - insertedIDs: The objectIDs of the inserted messages to rehydrate
    ///   - sendersByID: Dictionary of senders by qualified ID
    ///   - conversationsByID: Dictionary of conversation by qualified ID
    ///   - genericMessagesByNonce: Dictionary of generic messages by nonce
    /// - Returns: The rehydration result count

    private func rehydrateAllMessages(
        insertedIDs: [NSManagedObjectID],
        sendersByID: [QualifiedID: ZMUser],
        conversationsByID: [QualifiedID: ZMConversation],
        rehydrationDataByNonce: [UUID: RehydrationData],
    ) async throws -> ImportResult.ResultCount {
        var restoredCount = 0
        var failedCount = 0

        await backupContext.perform {

            var failedObjectIDs: [NSManagedObjectID] = []

            // Connect relationships and set generic message data
            for objectID in insertedIDs {
                autoreleasepool {
                    do {
                        try rehydrateSingleMessage(
                            objectID: objectID,
                            sendersByID: sendersByID,
                            conversationsByID: conversationsByID,
                            rehydrationDataByNonce: rehydrationDataByNonce
                        )
                        restoredCount += 1
                    } catch {
                        WireLogger.backupImport.warn("failed to rehydrate message: \(String(describing: error))")
                        failedObjectIDs.append(objectID)
                        failedCount += 1
                    }
                }
            }

            // Remove failed objects
            if !failedObjectIDs.isEmpty {
                do {
                    let deleteRequest = NSBatchDeleteRequest(objectIDs: failedObjectIDs)
                    try backupContext.execute(deleteRequest)
                } catch {
                    WireLogger.backupImport.warn("Failed to delete invalid messages \(String(describing: error))")
                }
            }
        }

        return .init(
            successCount: restoredCount,
            failureCount: failedCount
        )
    }

    private enum RehydrationFailure: Error {
        case failedToGetMessageFromCoreData
        case failedToGetMessageNonce
        case failedToGetRehydrationData
        case failedToGetConversation
        case failedToSetGenericMessage(error: Error)
    }

    private func rehydrateSingleMessage(
        objectID: NSManagedObjectID,
        sendersByID: [QualifiedID: ZMUser],
        conversationsByID: [QualifiedID: ZMConversation],
        rehydrationDataByNonce: [UUID: RehydrationData]
    ) throws {

        guard let message = backupContext.object(with: objectID) as? ZMOTRMessage else {
            throw RehydrationFailure.failedToGetMessageFromCoreData
        }

        // WORKAROUND: Force Core Data to refresh the object from the persistent store.
        //
        // Core Data has an entity-class registration issue where NSManagedObject subclasses
        // lazily register their entity descriptions through the Objective-C runtime. On first
        // app launch (before any entity-class mappings have been cached), NSBatchInsertRequest
        // writes directly to SQLite, and when we retrieve objects via object(with:), Core Data
        // returns instances with incomplete entity metadata - missing property type information,
        // causing SIGABRT crashes like "Could not cast '__NSCFNumber' to 'NSString'".
        //
        // Calling refresh() forces Core Data to reload the object from the persistent store,
        // which properly initializes the entity description and all property metadata.
        //
        // This same issue causes the Core Data errors seen in logs:
        // "Failed to find a unique match for an NSEntityDescription to a managed object subclass"
        //
        // Works after relaunch because the entity-class mappings get cached during normal use.
        backupContext.refresh(message, mergeChanges: false)

        guard let nonce = message.nonce else {
            throw RehydrationFailure.failedToGetMessageNonce
        }

        guard let rehydrationData = rehydrationDataByNonce[nonce] else {
            throw RehydrationFailure.failedToGetRehydrationData
        }

        guard let conversation = conversationsByID[rehydrationData.conversationID] else {
            throw RehydrationFailure.failedToGetConversation
        }

        do {
            try setGenericMessage(rehydrationData.genericMessage, for: message)

            if let sender = sendersByID[rehydrationData.senderID] {
                message.sender = sender
            }

            message.visibleInConversation = conversation
            message.markAsSent()
        } catch {
            throw RehydrationFailure.failedToSetGenericMessage(error: error)
        }
    }

    private func setGenericMessage(_ genericMessage: GenericMessage, for message: ZMOTRMessage) throws {
        if let message = message as? ZMClientMessage {

            try message.setNewUnderlyingMessage(genericMessage)

        } else if let message = message as? ZMAssetClientMessage {

            try message.setNewUnderlyingMessage(genericMessage)

            // We assume received assets are V3 since backend no longer supports sending V2 assets.
            message.version = 3

            assetTransferStateResolver.resolveTransferState(
                assetMessage: message,
                genericMessage: genericMessage,
                context: backupContext
            )
        }
    }

}

// MARK: - Fetching messages

extension BackupLocalStore {

    private var messageFetchRequest: NSFetchRequest<any NSFetchRequestResult> {
        let fetchRequest = ZMMessage.fetchRequest()
        fetchRequest.fetchBatchSize = 50
        fetchRequest.returnsObjectsAsFaults = true
        fetchRequest.includesPropertyValues = false
        return fetchRequest
    }

}

// MARK: - Helpers

extension WireDataModel.QualifiedID {
    func toFoundationQualifiedID() -> WireFoundation.QualifiedID {
        WireFoundation.QualifiedID(id: uuid, domain: domain)
    }
}
