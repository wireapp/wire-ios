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
import WireDomainSupport
import XCTest

final class UserClientsRepositoryTests: XCTestCase {

    private var sut: UserClientsRepository!
    private var userClientsAPI: MockUserClientsAPI!
    private var userRepository: MockUserRepositoryProtocol!
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
        userClientsAPI = MockUserClientsAPI()
        userRepository = MockUserRepositoryProtocol()
        sut = UserClientsRepository(
            userClientsAPI: userClientsAPI,
            userRepository: userRepository,
            context: context
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        stack = nil
        userClientsAPI = nil
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

    func testPullSelfClients() async throws {
        // Mock

        let selfUser = await context.perform { [self] in
            let selfUser = modelHelper.createSelfUser(id: UUID(), in: context)
            modelHelper.createSelfClient(
                id: Scaffolding.userClientID,
                in: context
            )

            modelHelper.createSelfClient(
                id: Scaffolding.otherUserClientID,
                in: context
            )

            return selfUser
        }

        await context.perform {
            let selfUserClientsIDs = selfUser.clients.map(\.remoteIdentifier)
            XCTAssertTrue(selfUserClientsIDs.contains(Scaffolding.userClientID))
            XCTAssertTrue(selfUserClientsIDs.contains(Scaffolding.otherUserClientID))
        }

        userClientsAPI.getSelfClients_MockValue = [
            Scaffolding.selfUserClient
        ]

        userRepository.fetchSelfUser_MockValue = selfUser

        // When

        try await sut.pullSelfClients()

        // Then

        try await context.perform {
            let selfUserClientsIDs = selfUser.clients.map(\.remoteIdentifier)
            XCTAssertTrue(selfUserClientsIDs.contains(Scaffolding.userClientID))
            XCTAssertFalse(selfUserClientsIDs.contains(Scaffolding.otherUserClientID)) // should be deleted

            let updatedClient = try XCTUnwrap(selfUser.clients.first(where: { $0.remoteIdentifier == Scaffolding.userClientID })) // should be updated

            XCTAssertEqual(updatedClient.type.rawValue, Scaffolding.selfUserClient.type.rawValue)
            XCTAssertEqual(updatedClient.label, Scaffolding.selfUserClient.label)
            XCTAssertEqual(updatedClient.model, Scaffolding.selfUserClient.model)
        }
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
        static let otherUserClientID = UUID().uuidString

        static let selfUserClient = WireAPI.SelfUserClient(
            id: userClientID,
            type: .permanent,
            activationDate: .now,
            label: "test",
            model: "test",
            deviceClass: .phone,
            capabilities: []
        )

        static let selfUserOtherClient = WireAPI.SelfUserClient(
            id: otherUserClientID,
            type: .permanent,
            activationDate: .now,
            label: "test",
            model: "test",
            deviceClass: .phone,
            capabilities: []
        )

    }

}
