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
import Testing
import WireDataModelSupport

@testable import WireSyncEngine

struct AppVersionMigration_4_30_0Tests {

    let coreDataHelper = CoreDataStackHelper()
    let modelHelper = ModelHelper()

    let stack: CoreDataStack
    let sut: AppVersionMigration_4_30_0

    init() async throws {
        self.stack = try await coreDataHelper.createStack()
        self.sut = AppVersionMigration_4_30_0(coreDataStack: stack)
    }

    @Test("Removes duplicate users sharing the same remote identifier and domain, keeping one")
    func testRemovesDuplicateUser() async throws {
        let context = stack.syncContext

        let id = UUID()
        let domain = "example.com"
        var keptUser: ZMUser?

        try await context.perform {
            modelHelper.createSelfUser(in: context)
            keptUser = modelHelper.createUser(id: id, domain: domain, in: context)
            keptUser?.needsToBeUpdatedFromBackend = false
            let duplicateUser = modelHelper.createUser(id: id, domain: domain, in: context)
            duplicateUser.needsToBeUpdatedFromBackend = false
            // Force distinct, ordered primaryKey values so both rows survive the save (reproducing
            // WPB-22498, where two rows shared the same identity but not the same primaryKey) and so
            // the migration's deterministic "lowest primaryKey wins" tie-break keeps `keptUser`.
            keptUser?.setValue("0-kept", forKey: "primaryKey")
            duplicateUser.setValue("1-duplicate", forKey: "primaryKey")
            try context.save()
        }

        // WHEN
        try await sut.perform()

        // THEN
        try await context.perform {
            let request = NSFetchRequest<ZMUser>(entityName: ZMUser.entityName())
            let remainingUsers = try context.fetch(request).filter {
                $0.remoteIdentifier == id && $0.domain == domain
            }

            #expect(remainingUsers.count == 1)
            let survivor = try #require(remainingUsers.first)
            #expect(survivor.objectID == keptUser?.objectID)
            #expect(survivor.needsToBeUpdatedFromBackend)
        }
    }

    @Test("Leaves users with different domains for the same remote identifier untouched")
    func testDoesNotRemoveUsersWithDifferentDomains() async throws {
        let context = stack.syncContext

        let id = UUID()

        try await context.perform {
            modelHelper.createSelfUser(in: context)
            _ = modelHelper.createUser(id: id, domain: "example.com", in: context)
            _ = modelHelper.createUser(id: id, domain: "other.com", in: context)
            try context.save()
        }

        // WHEN
        try await sut.perform()

        // THEN
        try await context.perform {
            let request = NSFetchRequest<ZMUser>(entityName: ZMUser.entityName())
            let remainingUsers = try context.fetch(request).filter { $0.remoteIdentifier == id }
            #expect(remainingUsers.count == 2)
        }
    }

    @Test("Treats an empty-string domain and a nil domain as the same identity")
    func testTreatsEmptyAndNilDomainAsDuplicates() async throws {
        let context = stack.syncContext

        let id = UUID()
        var keptUser: ZMUser?

        try await context.perform {
            modelHelper.createSelfUser(in: context)
            keptUser = modelHelper.createUser(id: id, domain: nil, in: context)
            let duplicateUser = modelHelper.createUser(id: id, domain: nil, in: context)
            // Bypass the normalizing `domain` setter to reproduce a pre-existing row whose domain
            // was persisted as "" instead of nil (WPB-22498), rather than normalized at write time.
            duplicateUser.setValue("", forKey: "domain")
            keptUser?.setValue("0-kept", forKey: "primaryKey")
            duplicateUser.setValue("1-duplicate", forKey: "primaryKey")
            try context.save()
        }

        // WHEN
        try await sut.perform()

        // THEN
        try await context.perform {
            let request = NSFetchRequest<ZMUser>(entityName: ZMUser.entityName())
            let remainingUsers = try context.fetch(request).filter { $0.remoteIdentifier == id }

            #expect(remainingUsers.count == 1)
            #expect(remainingUsers.first?.objectID == keptUser?.objectID)
        }
    }

    @Test("Transfers a to-one relationship from the duplicate onto the kept user")
    func testTransfersToOneRelationship() async throws {
        let context = stack.syncContext

        let id = UUID()
        var keptUser: ZMUser?
        var connection: ZMConnection?

        try await context.perform {
            modelHelper.createSelfUser(in: context)
            keptUser = modelHelper.createUser(id: id, domain: "example.com", in: context)
            let duplicateUser = modelHelper.createUser(id: id, domain: "example.com", in: context)
            keptUser?.setValue("0-kept", forKey: "primaryKey")
            duplicateUser.setValue("1-duplicate", forKey: "primaryKey")
            (connection, _) = modelHelper.createConnection(status: .accepted, to: duplicateUser, in: context)
            try context.save()
        }

        // WHEN
        try await sut.perform()

        // THEN
        try await context.perform {
            let survivor = try #require(keptUser)
            #expect(survivor.connection?.objectID == connection?.objectID)
            #expect(connection?.to?.objectID == survivor.objectID)
        }
    }

    @Test("Transfers a to-many relationship from the duplicate onto the kept user")
    func testTransfersToManyRelationship() async throws {
        let context = stack.syncContext

        let id = UUID()
        var keptUser: ZMUser?
        var client: UserClient?

        try await context.perform {
            modelHelper.createSelfUser(in: context)
            keptUser = modelHelper.createUser(id: id, domain: "example.com", in: context)
            let duplicateUser = modelHelper.createUser(id: id, domain: "example.com", in: context)
            keptUser?.setValue("0-kept", forKey: "primaryKey")
            duplicateUser.setValue("1-duplicate", forKey: "primaryKey")
            client = modelHelper.createClient(for: duplicateUser)
            try context.save()
        }

        // WHEN
        try await sut.perform()

        // THEN
        try await context.perform {
            let survivor = try #require(keptUser)
            let transferredClient = try #require(client)
            #expect(survivor.clients.contains(transferredClient))
            #expect(transferredClient.user?.objectID == survivor.objectID)
        }
    }

    @Test("Leaves non duplicated users untouched")
    func testLeavesUniqueUserUnchanged() async throws {
        let context = stack.syncContext

        var user: ZMUser?

        try await context.perform {
            modelHelper.createSelfUser(in: context)
            user = modelHelper.createUser(domain: "example.com", in: context)
            user?.needsToBeUpdatedFromBackend = false
            try context.save()
        }

        // WHEN
        try await sut.perform()

        // THEN
        try await context.perform {
            let unchanged = try #require(user)
            #expect(!unchanged.needsToBeUpdatedFromBackend)
            #expect(!unchanged.isDeleted)
        }
    }
}
