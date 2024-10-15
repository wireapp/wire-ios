//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

@testable import WireAPI
import WireAPISupport
import WireDataModel
import WireDataModelSupport
@testable import WireDomain
import XCTest

final class ClientRepositoryTests: XCTestCase {

    private var sut: ClientRepository!
    private var clientAPI: MockClientAPI!
    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()
        stack = try await coreDataStackHelper.createStack()
        clientAPI = MockClientAPI()
        sut = ClientRepository(
            clientAPI: clientAPI,
            context: context
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        stack = nil
        clientAPI = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        modelHelper = nil
    }

    // MARK: - Tests

    func testFetchOrCreateClient() async throws {
        // Given

        await context.perform { [self] in
            let userClient = modelHelper.createSelfClient(
                id: Scaffolding.userClientID,
                in: context
            )

            XCTAssertEqual(userClient.remoteIdentifier, Scaffolding.userClientID)
        }

        // When

        let userClient = try await sut.fetchOrCreateClient(
            with: Scaffolding.userClientID
        )

        // Then

        XCTAssertNotNil(userClient)
    }

    func testUpdatesClient() async throws {
        // Given

        let createdClient = try await sut.fetchOrCreateClient(
            with: Scaffolding.userClientID
        )

        // When

        try await sut.updateClient(
            with: createdClient.client.remoteIdentifier!,
            from: Scaffolding.selfUserClient,
            isNewClient: createdClient.isNew
        )

        // Then

        try await context.perform { [context] in
            let updatedClient = try XCTUnwrap(UserClient.fetchExistingUserClient(
                with: Scaffolding.userClientID,
                in: context
            ))

            XCTAssertEqual(updatedClient.remoteIdentifier, Scaffolding.userClientID)
            XCTAssertEqual(updatedClient.type, .permanent)
            XCTAssertEqual(updatedClient.label, Scaffolding.selfUserClient.label)
            XCTAssertEqual(updatedClient.model, Scaffolding.selfUserClient.model)
            XCTAssertEqual(updatedClient.deviceClass, .phone)
        }
    }

    func testFetchSelfClients() async throws {
        // Mock

        clientAPI.getSelfClients_MockValue = [Scaffolding.selfUserClient]

        // When

        let selfClients = try await sut.fetchSelfClients()

        // Then

        XCTAssertEqual(selfClients, [Scaffolding.selfUserClient])
    }

    func testFetchClients() async throws {
        // Mock

        clientAPI.getClientsFor_MockValue = [Scaffolding.userClients1, Scaffolding.userClients2]

        // When

        let userClients = try await sut.fetchClients(for: [.mockID1, .mockID2, .mockID3])

        // Then

        XCTAssertEqual(userClients, [Scaffolding.userClients1, Scaffolding.userClients2])
    }

    func testDeleteClients() async throws {
        // Given

        let (newClient, _) = try await sut.fetchOrCreateClient(with: Scaffolding.userClientID)

        let localClient = await context.perform { [context] in
            WireDataModel.UserClient.fetchExistingUserClient(
                with: Scaffolding.userClientID,
                in: context
            )
        }

        XCTAssertEqual(localClient, newClient)

        // When

        await sut.deleteClient(with: Scaffolding.userClientID)

        // Then

        let deletedClient = await context.perform { [context] in
            WireDataModel.UserClient.fetchExistingUserClient(
                with: Scaffolding.userClientID,
                in: context
            )
        }

        XCTAssertEqual(deletedClient, nil)
    }

    private enum Scaffolding {
        static let userClientID = UUID().uuidString

        static let selfUserClient = WireAPI.UserClient(
            id: userClientID,
            type: .permanent,
            activationDate: .now,
            label: "test",
            model: "test",
            deviceClass: .phone,
            capabilities: []
        )

        static let userClients1 = WireAPI.UserClients(
            domain: "domain.com",
            userID: UUID(),
            clients: [.init(id: "foo", deviceClass: .legalhold)]
        )

        static let userClients2 = WireAPI.UserClients(
            domain: "domain.com",
            userID: UUID(),
            clients: [.init(id: "foo", deviceClass: .phone)]
        )
    }

}
