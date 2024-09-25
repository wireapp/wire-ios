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
    let coreDataStackHelper = CoreDataStackHelper()
    let modelHelper = ModelHelper()

    var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        stack = try await coreDataStackHelper.createStack()
        usersAPI = MockUsersAPI()
        makeSut()
    }

    override func tearDown() async throws {
        stack = nil
        usersAPI = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    func makeSut(isFederationEnabled: Bool = true) {
        sut = UserRepository(
            context: context,
            usersAPI: usersAPI,
            isFederationEnabled: isFederationEnabled
        )
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

    func testUpdateUser_It_Updates_User_Locally_With_Federation_Enabled() async throws {
        // Given

        modelHelper.createUser(id: Scaffolding.userID, in: context)

        // When

        try await sut.updateUser(from: Scaffolding.event)

        // Then

        try await context.perform { [context] in
            let updatedUser = try XCTUnwrap(ZMUser.fetch(with: Scaffolding.userID, in: context))

            XCTAssertEqual(updatedUser.remoteIdentifier, Scaffolding.userID)
            XCTAssertEqual(updatedUser.domain, Scaffolding.domain) /// federation enabled, domain is set
            XCTAssertEqual(updatedUser.name, Scaffolding.event.name)
            XCTAssertEqual(updatedUser.handle, Scaffolding.event.handle)
            XCTAssertEqual(updatedUser.emailAddress, Scaffolding.event.email)
            XCTAssertEqual(updatedUser.supportedProtocols, [.proteus, .mls])
        }
    }

    func testUpdateUser_It_Updates_User_Locally_With_Federation_Disabled() async throws {
        // Given

        makeSut(isFederationEnabled: false)
        modelHelper.createUser(id: Scaffolding.userID, in: context)

        // When

        try await sut.updateUser(from: Scaffolding.event)

        // Then

        try await context.perform { [context] in
            let updatedUser = try XCTUnwrap(ZMUser.fetch(with: Scaffolding.userID, in: context))

            XCTAssertEqual(updatedUser.remoteIdentifier, Scaffolding.userID)
            XCTAssertNil(updatedUser.domain) /// federation disabled, domain is nil
            XCTAssertEqual(updatedUser.name, Scaffolding.event.name)
            XCTAssertEqual(updatedUser.handle, Scaffolding.event.handle)
            XCTAssertEqual(updatedUser.emailAddress, Scaffolding.event.email)
            XCTAssertEqual(updatedUser.supportedProtocols, [.proteus, .mls])
        }
    }

    private enum Scaffolding {
        static let userID = UUID()
        static let domain = "domain.com"

        nonisolated(unsafe) static let user1 = User(
            id: QualifiedID(uuid: userID, domain: domain),
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

        nonisolated(unsafe) static let event = UserUpdateEvent(
            id: userID,
            userID: UserID(uuid: userID, domain: domain),
            accentColorID: nil,
            name: "username",
            handle: "test",
            email: "test@wire.com",
            isSSOIDDeleted: nil,
            assets: nil,
            supportedProtocols: [.proteus, .mls]
        )
    }

}
