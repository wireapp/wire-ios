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

import CoreData
package import Foundation
package import WireData
package import WireMessagingDomain

private typealias ManagedUpload = WireData.WireDriveDirectUpload

/// Persists Wire Drive direct uploads in Core Data via a background context.
package final class WireDriveDirectUploadStore: WireDriveDirectUploadStoreProtocol {

    private let contextProvider: any ManagedObjectContextProvider

    package init(contextProvider: any ManagedObjectContextProvider) {
        self.contextProvider = contextProvider
    }

    // MARK: - Fetching

    package func fetchAll() async throws -> [WireDriveDirectUploadRecord] {
        let context = contextProvider.newBackgroundContext()
        return try await context.perform {
            try context.fetchUploads(predicate: nil).map(\.toRecord)
        }
    }

    package func fetch(uploadID: UUID) async throws -> WireDriveDirectUploadRecord? {
        let context = contextProvider.newBackgroundContext()
        return try await context.perform {
            try context.fetchUpload(uploadID: uploadID)?.toRecord
        }
    }

    package func fetch(states: [WireDriveDirectUploadRecord.State]) async throws -> [WireDriveDirectUploadRecord] {
        let rawValues = states.map(\.rawValue)
        let context = contextProvider.newBackgroundContext()
        return try await context.perform {
            let predicate = NSPredicate(format: "state IN %@", rawValues)
            return try context.fetchUploads(predicate: predicate).map(\.toRecord)
        }
    }

    // MARK: - Writing

    package func upsert(_ record: WireDriveDirectUploadRecord) async throws {
        try await upsert(records: [record])
    }

    package func upsert(records: [WireDriveDirectUploadRecord]) async throws {
        guard !records.isEmpty else { return }

        let context = contextProvider.newBackgroundContext()
        try await context.perform {
            for record in records {
                let stored = try context.fetchUpload(uploadID: record.uploadID)
                    ?? context.insertUpload()

                // Skip the write when nothing durable changed. Without this, a caller that
                // refreshes `updatedAt` on every event would churn the store.
                if let existing = stored.managedObjectContext.map({ _ in stored }),
                   existing.hasPersistedIdentity,
                   existing.toRecord.hasEqualPersistedFields(to: record) {
                    continue
                }

                stored.apply(record)
            }

            guard context.hasChanges else { return }
            try context.save()
        }
    }

    package func delete(uploadIDs: [UUID]) async throws {
        guard !uploadIDs.isEmpty else { return }

        let context = contextProvider.newBackgroundContext()
        try await context.perform {
            for uploadID in uploadIDs {
                if let stored = try context.fetchUpload(uploadID: uploadID) {
                    context.delete(stored)
                }
            }

            guard context.hasChanges else { return }
            try context.save()
        }
    }

    package func deleteAll() async throws {
        let context = contextProvider.newBackgroundContext()
        try await context.perform {
            for stored in try context.fetchUploads(predicate: nil) {
                context.delete(stored)
            }

            guard context.hasChanges else { return }
            try context.save()
        }
    }
}

// MARK: - Mapping

private extension ManagedUpload {

    /// Whether this object already represents a persisted upload, as opposed to one just inserted.
    var hasPersistedIdentity: Bool {
        !objectID.isTemporaryID
    }

    var toRecord: WireDriveDirectUploadRecord {
        WireDriveDirectUploadRecord(
            uploadID: uploadID,
            batchID: batchID,
            nodeID: nodeID,
            versionID: versionID,
            destinationFolderPath: destinationFolderPath,
            nodePath: nodePath,
            fileName: fileName,
            fileSize: fileSize >= 0 ? UInt64(fileSize) : 0,
            mimeType: mimeType,
            stagedFileName: stagedFileName,
            state: WireDriveDirectUploadRecord.State(rawValue: state) ?? .failed,
            createdAt: createdAt,
            updatedAt: updatedAt,
            attemptCount: Int(attemptCount),
            sessionIdentifier: sessionIdentifier,
            taskIdentifier: taskIdentifier >= 0 ? Int(taskIdentifier) : nil,
            presignedURL: presignedURL.flatMap(URL.init(string:)),
            presignedURLExpiresAt: presignedURLExpiresAt,
            presignedRequestHeaders: presignedRequestHeaders.flatMap(Self.decodeHeaders) ?? [:],
            failure: WireDriveUploadError(
                reasonCode: WireDriveUploadError.ReasonCode(rawValue: failureReasonCode) ?? .none,
                message: failureMessage
            )
        )
    }

    func apply(_ record: WireDriveDirectUploadRecord) {
        uploadID = record.uploadID
        batchID = record.batchID
        nodeID = record.nodeID
        versionID = record.versionID
        destinationFolderPath = record.destinationFolderPath
        nodePath = record.nodePath
        fileName = record.fileName
        fileSize = Int64(record.fileSize)
        mimeType = record.mimeType
        stagedFileName = record.stagedFileName
        state = record.state.rawValue
        createdAt = record.createdAt
        updatedAt = record.updatedAt
        attemptCount = Int16(clamping: record.attemptCount)
        sessionIdentifier = record.sessionIdentifier
        taskIdentifier = record.taskIdentifier.map(Int64.init) ?? -1
        presignedURL = record.presignedURL?.absoluteString
        presignedURLExpiresAt = record.presignedURLExpiresAt
        presignedRequestHeaders = record.presignedRequestHeaders.isEmpty
            ? nil
            : Self.encodeHeaders(record.presignedRequestHeaders)
        failureReasonCode = (record.failure?.reasonCode ?? .none).rawValue
        failureMessage = record.failure?.reasonMessage
    }

    static func encodeHeaders(_ headers: [String: String]) -> String? {
        guard let data = try? JSONEncoder().encode(headers) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func decodeHeaders(_ json: String) -> [String: String]? {
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([String: String].self, from: data)
    }
}

private extension NSManagedObjectContext {

    func insertUpload() -> ManagedUpload {
        guard let entity = NSEntityDescription.entity(forEntityName: ManagedUpload.entityName, in: self) else {
            fatalError("\(ManagedUpload.entityName) is missing from the managed object model")
        }

        return ManagedUpload(entity: entity, insertInto: self)
    }

    func fetchUpload(uploadID: UUID) throws -> ManagedUpload? {
        let request = ManagedUpload.fetchRequest() as! NSFetchRequest<ManagedUpload>
        request.predicate = NSPredicate(format: "uploadID == %@", uploadID as any CVarArg)
        request.fetchLimit = 1
        return try fetch(request).first
    }

    func fetchUploads(predicate: NSPredicate?) throws -> [ManagedUpload] {
        let request = ManagedUpload.fetchRequest() as! NSFetchRequest<ManagedUpload>
        request.predicate = predicate
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return try fetch(request)
    }
}
