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

import WireDataModel
import WireDataModelSupport
import WireDomainSupport
import WireTestingPackage
import XCTest

@testable import WireDomain

final class UserClientsLocalStoreTests: XCTestCase {

    private var sut: UserClientsLocalStore!
    private var userLocalStore: MockUserLocalStoreProtocol!
    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()
        stack = try await coreDataStackHelper.createStack()
        userLocalStore = MockUserLocalStoreProtocol()

        sut = UserClientsLocalStore(
            context: context
        )
    }

    override func tearDown() async throws {
        stack = nil
        userLocalStore = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        modelHelper = nil
    }

    // MARK: - Tests

    func testFetchOrCreateClient_It_Retrieves_Client_Locally() async {
        // Given

        await context.perform { [self] in
            let userClient = modelHelper.createSelfClient(
                id: Scaffolding.userClientID,
                in: context
            )

            XCTAssertEqual(userClient.remoteIdentifier, Scaffolding.userClientID)
        }

        // When

        let userClient = await sut.fetchOrCreateClient(
            id: Scaffolding.userClientID
        )

        // Then

        await context.perform {
            XCTAssertNotNil(userClient)
        }
    }

    func testUpdateClient_It_Inserts_New_Client_Info() async throws {
        // Given

        let selfClient = await context.perform { [context] in
            ModelHelper().createSelfClient(in: context)
        }

        let createdClient = await sut.fetchOrCreateClient(
            id: Scaffolding.userClientID
        ).client

        let clientID = await context.perform {
            createdClient.remoteIdentifier!
        }

        // When

        await sut.updateClient(
            id: clientID,
            isNewClient: true,
            userClientInfo: Scaffolding.selfUserClientInfo
        )

        // Then

        try await context.perform { [context] in
            let updatedClient = try XCTUnwrap(UserClient.fetchExistingUserClient(
                with: Scaffolding.userClientID,
                in: context
            ))

            XCTAssertEqual(updatedClient.remoteIdentifier, Scaffolding.userClientID)
            XCTAssertEqual(updatedClient.type, .permanent)
            XCTAssertEqual(updatedClient.label, Scaffolding.selfUserClientInfo.label)
            XCTAssertEqual(updatedClient.model, Scaffolding.selfUserClientInfo.model)
            XCTAssertEqual(updatedClient.deviceClass, .phone)
            XCTAssertTrue(updatedClient.needsSessionMigration)

            XCTAssertTrue(selfClient.ignoredClients.contains(updatedClient))
            XCTAssertFalse(selfClient.trustedClients.contains(updatedClient))
        }
    }

    func testUpdateClient_It_Updates_Existing_Client_Info() async throws {
        // Given

        let selfClient = await context.perform { [context] in
            ModelHelper().createSelfClient(in: context)
        }

        let createdClient = await sut.fetchOrCreateClient(
            id: Scaffolding.userClientID
        ).client

        let clientID = await context.perform {
            createdClient.remoteIdentifier!
        }

        // When

        await sut.updateClient(
            id: clientID,
            isNewClient: false,
            userClientInfo: Scaffolding.selfUserClientInfo
        )

        // Then

        try await context.perform { [context] in
            let updatedClient = try XCTUnwrap(UserClient.fetchExistingUserClient(
                with: Scaffolding.userClientID,
                in: context
            ))

            XCTAssertEqual(updatedClient.remoteIdentifier, Scaffolding.userClientID)
            XCTAssertEqual(updatedClient.type, .permanent)
            XCTAssertEqual(updatedClient.label, Scaffolding.selfUserClientInfo.label)
            XCTAssertEqual(updatedClient.model, Scaffolding.selfUserClientInfo.model)
            XCTAssertEqual(updatedClient.deviceClass, .phone)

            XCTAssertFalse(selfClient.ignoredClients.contains(updatedClient))
            XCTAssertFalse(selfClient.trustedClients.contains(updatedClient))
        }
    }

    func testDeleteClient_It_Deletes_Client_Locally() async throws {
        // Given

        let (newClient, _) = await sut.fetchOrCreateClient(id: Scaffolding.userClientID)

        let localClient = await context.perform { [context] in
            WireDataModel.UserClient.fetchExistingUserClient(
                with: Scaffolding.userClientID,
                in: context
            )
        }

        XCTAssertEqual(localClient, newClient)

        // When

        await sut.deleteClient(id: Scaffolding.userClientID)

        // Then

        let deletedClient = await context.perform { [context] in
            WireDataModel.UserClient.fetchExistingUserClient(
                with: Scaffolding.userClientID,
                in: context
            )
        }

        XCTAssertEqual(deletedClient, nil)
    }

    func testInvalidateSelfClient_It_Resets_Self_Client_Locally() async throws {
        // Given

        let selfClient = await context.perform { [self] in
            let selfClient = modelHelper.createSelfClient(in: context)
            selfClient.remoteIdentifier = UUID.mockID1.uuidString
            selfClient.mlsPublicKeys = .init(ed25519: "key")
            selfClient.setLocallyModifiedKeys(Set(["missingClients"]))
            context.setPersistentStoreMetadata(
                selfClient.remoteIdentifier!,
                key: ZMPersistedClientIdKey
            )

            XCTAssertEqual(selfClient.remoteIdentifier, UUID.mockID1.uuidString)
            XCTAssertTrue(selfClient.hasLocalModifications(forKey: "missingClients"))
            XCTAssertEqual(
                context.userInfo["ZMMetadataKey"] as! NSMutableDictionary,
                ["PersistedClientId": selfClient.remoteIdentifier!]
            )
            XCTAssertEqual(selfClient.mlsPublicKeys, .init(ed25519: "key"))

            return selfClient
        }

        // When

        await sut.invalidateSelfClient()

        // Then

        await context.perform { [context] in
            XCTAssertEqual(selfClient.remoteIdentifier, nil)
            XCTAssertFalse(selfClient.hasLocalModifications(forKey: "missingClients"))
            XCTAssertEqual(
                context.userInfo["ZMMetadataKey"] as? NSMutableDictionary,
                nil
            )
            XCTAssertEqual(selfClient.mlsPublicKeys, .init())
        }
    }

    private enum Scaffolding {
        static let userClientID = UUID.mockID1.uuidString
        static let otherUserClientID = UUID.mockID2.uuidString

        static let selfUserClientInfo = UserClientInfo(
            id: userClientID,
            label: "test",
            type: .permanent,
            activationDate: .now,
            model: "test",
            deviceClass: .phone,
            lastActiveDate: nil,
            mlsPublicKeys: nil,
            capabilities: [.legalholdConsent]
        )

    }

}
