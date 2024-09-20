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

import Foundation
import WireAPISupport
import WireDataModel
import WireDataModelSupport
import XCTest

@testable import WireAPI
@testable import WireDomain

class UserRepositoryTests: XCTestCase {

    var sut: UserRepository!
    var usersAPI: MockUsersAPI!

    var stack: CoreDataStack!
    var coreDataStackHelper: CoreDataStackHelper!
    var modelHelper: ModelHelper!

    var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()
        stack = try await coreDataStackHelper.createStack()
        usersAPI = MockUsersAPI()
        sut = UserRepository(
            context: context,
            usersAPI: usersAPI
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        stack = nil
        usersAPI = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        modelHelper = nil
    }

    // MARK: - Tests

    func testPullUsers() async throws {
        // Given
        await context.perform { [context] in
            // There is no user in the database.
            XCTAssertNil(ZMUser.fetch(with: Scaffolding.user1.id.uuid, domain: Scaffolding.user1.id.domain, in: context))
        }

        // Mock
        usersAPI.getUsersUserIDs_MockValue = WireAPI.UserList(
            found: [Scaffolding.user1],
            failed: []
        )

        // When
        try await sut.pullUsers(userIDs: [Scaffolding.user1.id.toDomainModel()])

        // Then
        try await context.perform { [context] in
            // There is a user in the database.
            let user = try XCTUnwrap(
                ZMUser.fetch(
                    with: Scaffolding.user1.id.uuid,
                    domain: Scaffolding.user1.id.domain,
                    in: context
                )
            )
            XCTAssertEqual(user.remoteIdentifier, Scaffolding.user1.id.uuid)
            XCTAssertEqual(user.name, Scaffolding.user1.name)
            XCTAssertEqual(user.handle, Scaffolding.user1.handle)
            XCTAssertEqual(user.teamIdentifier, Scaffolding.user1.teamID)
            XCTAssertEqual(user.accentColorValue, Int16(Scaffolding.user1.accentID))
            XCTAssertEqual(user.isAccountDeleted, Scaffolding.user1.deleted)
            XCTAssertEqual(user.emailAddress, Scaffolding.user1.email)
            XCTAssertEqual(user.supportedProtocols, Scaffolding.user1.supportedProtocols?.toDomainModel())
            XCTAssertFalse(user.needsToBeUpdatedFromBackend)
        }
    }

    func testPullKnownUsers() async throws {
        // Given
        _ = await context.perform { [context] in
            // Insert incomplete user in the database.
            ZMUser.fetchOrCreate(with: Scaffolding.user1.id.uuid, domain: Scaffolding.user1.id.domain, in: context)
        }

        // Mock
        usersAPI.getUsersUserIDs_MockValue = WireAPI.UserList(
            found: [Scaffolding.user1],
            failed: []
        )

        // When
        try await sut.pullKnownUsers()

        // Then
        try await context.perform { [context] in
            // The complete user in the database.
            let user = try XCTUnwrap(
                ZMUser.fetch(
                    with: Scaffolding.user1.id.uuid,
                    domain: Scaffolding.user1.id.domain,
                    in: context
                )
            )
            XCTAssertEqual(user.remoteIdentifier, Scaffolding.user1.id.uuid)
            XCTAssertEqual(user.name, Scaffolding.user1.name)
            XCTAssertEqual(user.handle, Scaffolding.user1.handle)
            XCTAssertEqual(user.teamIdentifier, Scaffolding.user1.teamID)
            XCTAssertEqual(user.accentColorValue, Int16(Scaffolding.user1.accentID))
            XCTAssertEqual(user.isAccountDeleted, Scaffolding.user1.deleted)
            XCTAssertEqual(user.emailAddress, Scaffolding.user1.email)
            XCTAssertEqual(user.supportedProtocols, Scaffolding.user1.supportedProtocols?.toDomainModel())
            XCTAssertFalse(user.needsToBeUpdatedFromBackend)
        }
    }

    func testFetchOrCreateUserClient() async throws {
        // Given

        await context.perform { [self] in
            let userClient = modelHelper.createSelfClient(
                id: Scaffolding.userClientID,
                in: context
            )

            XCTAssertEqual(userClient.remoteIdentifier, Scaffolding.userClientID)
        }

        // When

        let userClient = try await sut.fetchOrCreateUserClient(
            with: Scaffolding.userClientID
        )

        // Then

        XCTAssertNotNil(userClient)
    }

    func testUpdatesUserClient() async throws {
        // Given

        let createdClient = try await sut.fetchOrCreateUserClient(
            with: Scaffolding.userClientID
        )

        // When

        try await sut.updateUserClient(
            createdClient.client,
            from: Scaffolding.remoteUserClient,
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
            XCTAssertEqual(updatedClient.label, Scaffolding.remoteUserClient.label)
            XCTAssertEqual(updatedClient.model, Scaffolding.remoteUserClient.model)
            XCTAssertEqual(updatedClient.deviceClass, .phone)
        }
    }

    private enum Scaffolding {
        static let userID = UUID()

        static let userClientID = UUID().uuidString

        nonisolated(unsafe) static let remoteUserClient = WireAPI.UserClient(
            id: userClientID,
            type: .permanent,
            activationDate: .now,
            label: "test",
            model: "test",
            deviceClass: .phone,
            capabilities: []
        )

        nonisolated(unsafe) static let user1 = User(
            id: QualifiedID(uuid: UUID(), domain: "example.com"),
            name: "user1",
            handle: "handle1",
            teamID: nil,
            accentID: 1,
            assets: [],
            deleted: false,
            email: "john.doe@example.com",
            expiresAt: nil,
            service: nil,
            supportedProtocols: [.mls],
            legalholdStatus: .disabled
        )
    }

}
