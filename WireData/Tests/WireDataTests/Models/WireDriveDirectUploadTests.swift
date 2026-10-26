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
import Testing

@testable import WireData

@MainActor
struct WireDriveDirectUploadTests {

    private let container: NSPersistentContainer

    init() throws {
        self.container = try NSPersistentContainer.inMemoryContainer()
    }

    @Test
    func initialization() throws {
        // given
        let context = container.viewContext
        let uploadID = UUID()
        let batchID = UUID()
        let nodeID = UUID()
        let versionID = UUID()
        let createdAt = try Date.ISO8601FormatStyle().parse("2026-03-24T12:34:56Z")
        let updatedAt = try Date.ISO8601FormatStyle().parse("2026-03-24T12:35:56Z")
        let expiresAt = try Date.ISO8601FormatStyle().parse("2026-03-24T12:49:56Z")

        let upload = makeUpload(in: context)
        upload.uploadID = uploadID
        upload.batchID = batchID
        upload.nodeID = nodeID
        upload.versionID = versionID
        upload.destinationFolderPath = "cell-1/Documents"
        upload.nodePath = "cell-1/Documents/report.pdf"
        upload.fileName = "report.pdf"
        upload.fileSize = 2048
        upload.mimeType = "application/pdf"
        upload.stagedFileName = "\(uploadID.uuidString)_report.pdf"
        upload.state = 3
        upload.createdAt = createdAt
        upload.updatedAt = updatedAt
        upload.attemptCount = 1
        upload.sessionIdentifier = "com.wire.drive.upload-\(UUID().uuidString)"
        upload.taskIdentifier = 7
        upload.presignedURL = "https://example.com/io/cell-1/Documents/report.pdf?X-Amz-Signature=abc"
        upload.presignedURLExpiresAt = expiresAt
        upload.presignedRequestHeaders = nil
        upload.failureReasonCode = 0
        upload.failureMessage = nil

        // when
        try context.save()

        // then
        let request = try #require(WireDriveDirectUpload.fetchRequest() as? NSFetchRequest<WireDriveDirectUpload>)
        let persisted = try #require(context.fetch(request).first)

        #expect(persisted.uploadID == uploadID)
        #expect(persisted.batchID == batchID)
        #expect(persisted.nodeID == nodeID)
        #expect(persisted.versionID == versionID)
        #expect(persisted.destinationFolderPath == "cell-1/Documents")
        #expect(persisted.nodePath == "cell-1/Documents/report.pdf")
        #expect(persisted.fileName == "report.pdf")
        #expect(persisted.fileSize == 2048)
        #expect(persisted.mimeType == "application/pdf")
        #expect(persisted.stagedFileName == "\(uploadID.uuidString)_report.pdf")
        #expect(persisted.state == 3)
        #expect(persisted.createdAt == createdAt)
        #expect(persisted.updatedAt == updatedAt)
        #expect(persisted.attemptCount == 1)
        #expect(persisted.taskIdentifier == 7)
        #expect(persisted.presignedURLExpiresAt == expiresAt)
        #expect(persisted.presignedRequestHeaders == nil)
        #expect(persisted.failureReasonCode == 0)
        #expect(persisted.failureMessage == nil)
    }

    @Test
    func defaultValues() throws {
        // given
        let context = container.viewContext

        let upload = makeUpload(in: context)
        upload.uploadID = UUID()
        upload.batchID = UUID()
        upload.nodeID = UUID()
        upload.versionID = UUID()
        upload.destinationFolderPath = "cell-1"
        upload.nodePath = "cell-1/report.pdf"
        upload.fileName = "report.pdf"
        upload.stagedFileName = "staged"
        upload.createdAt = .init()
        upload.updatedAt = .init()

        // when
        try context.save()

        // then
        #expect(upload.state == 0)
        #expect(upload.fileSize == 0)
        #expect(upload.attemptCount == 0)
        #expect(upload.taskIdentifier == -1)
        #expect(upload.failureReasonCode == 0)
        #expect(upload.mimeType == nil)
        #expect(upload.presignedURL == nil)
        #expect(upload.presignedURLExpiresAt == nil)
    }

    /// Resolves the entity from the container's own model.
    ///
    /// `WireDriveDirectUpload(context:)` looks the entity up globally, which is ambiguous once several
    /// merged models are loaded — as happens here, with one container per test.
    private func makeUpload(in context: NSManagedObjectContext) -> WireDriveDirectUpload {
        let entity = NSEntityDescription.entity(forEntityName: WireDriveDirectUpload.entityName, in: context)!
        return WireDriveDirectUpload(entity: entity, insertInto: context)
    }

    @Test
    func entityName() {
        #expect(WireDriveDirectUpload.entityName == "WireDriveDirectUpload")

        let entity = NSEntityDescription.entity(
            forEntityName: WireDriveDirectUpload.entityName,
            in: container.viewContext
        )
        #expect(entity?.managedObjectClassName == "WireData.WireDriveDirectUpload")
    }

}
