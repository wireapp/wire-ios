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
import WireDomainSupport
import WireTestingPackage
import XCTest

@testable import WireAPI
@testable import WireDomain

class UserRepositoryTests: XCTestCase {

    var sut: UserRepository!
    var usersAPI: MockUsersAPI!
    var selfUsersAPI: MockSelfUserAPI!
    var conversationLabelsRepository: MockConversationLabelsRepositoryProtocol!

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
        selfUsersAPI = MockSelfUserAPI()
        conversationLabelsRepository = MockConversationLabelsRepositoryProtocol()
        sut = UserRepository(
            context: context,
            usersAPI: usersAPI,
            selfUserAPI: selfUsersAPI,
            conversationLabelsRepository: conversationLabelsRepository
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        stack = nil
        usersAPI = nil
        selfUsersAPI = nil
        conversationLabelsRepository = nil
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

    func testFetchSelfUser() async {
        // Given

        modelHelper.createSelfUser(
            id: Scaffolding.userID,
            domain: nil,
            in: context
        )

        // When

        let user = sut.fetchSelfUser()

        // Then

        await context.perform {
            XCTAssertEqual(user.remoteIdentifier, Scaffolding.userID)
        }
    }

    func testAddLegalholdRequest() async throws {
        // Given

        modelHelper.createSelfUser(
            id: Scaffolding.userID,
            domain: nil,
            in: context
        )

        // When

        await sut.addLegalHoldRequest(
            for: Scaffolding.userID,
            clientID: Scaffolding.userClientID,
            lastPrekey: Prekey(
                id: Scaffolding.lastPrekeyId,
                base64EncodedKey: Scaffolding.base64encodedString
            )
        )

        // Then

        try await context.perform { [context] in
            let selfUser = try XCTUnwrap(ZMUser.fetch(with: Scaffolding.userID, in: context))

            XCTAssertEqual(selfUser.legalHoldStatus, .pending(Scaffolding.legalHoldRequest))
        }
    }

    func testPushSelfSupportedProtocols() async throws {
        // Given
        selfUsersAPI.pushSupportedProtocols_MockMethod = { _ in () }
        XCTAssertEqual(selfUsersAPI.pushSupportedProtocols_Invocations, [])

        // When
        try await sut.pushSelfSupportedProtocols([.proteus])

        // Then
        let expectedProtocols = Set([WireAPI.MessageProtocol.proteus])

        XCTAssertEqual(selfUsersAPI.pushSupportedProtocols_Invocations, [expectedProtocols])
    }

    func testUpdateUserProperty_It_Enables_Read_Receipts_Property() async throws {
        // Given

        await context.perform { [self] in
            let selfUser = modelHelper.createSelfUser(
                id: Scaffolding.userID,
                domain: nil,
                in: context
            )

            selfUser.readReceiptsEnabled = false
            selfUser.readReceiptsEnabledChangedRemotely = false
        }

        // When

        try await sut.updateUserProperty(.areReadReceiptsEnabled(true))

        // Then

        try await context.perform { [self] in
            let selfUser = try XCTUnwrap(sut.fetchSelfUser())

            XCTAssertEqual(selfUser.readReceiptsEnabled, true)
            XCTAssertEqual(selfUser.readReceiptsEnabledChangedRemotely, true)
        }
    }

    func testUpdateUserProperty_Update_Conversation_Labels_Is_Invocated() async throws {
        // Mock

        conversationLabelsRepository.updateConversationLabels_MockMethod = { _ in }

        // When

        let conversationLabels = [Scaffolding.conversationLabel1, Scaffolding.conversationLabel2]

        try await sut.updateUserProperty(
            .conversationLabels(conversationLabels)
        )

        // Then

        XCTAssertEqual(
            conversationLabelsRepository.updateConversationLabels_Invocations.first,
            conversationLabels
        )
    }

    func testUpdateUserProperty_It_Throws_Error() async throws {
        // Mock

        conversationLabelsRepository.updateConversationLabels_MockError = ConversationLabelsRepositoryError.failedToDeleteStoredLabels

        // Then

        await XCTAssertThrowsError(ConversationLabelsRepositoryError.failedToDeleteStoredLabels) { [self] in

            // When

            try await sut.updateUserProperty(
                .conversationLabels([Scaffolding.conversationLabel1, Scaffolding.conversationLabel2])
            )
        }
    }

    private enum Scaffolding {
        static let userID = UUID()
        static let userClientID = UUID().uuidString
        static let lastPrekeyId = 65_535
        static let base64encodedString = "pQABAQoCoQBYIPEFMBhOtG0dl6gZrh3kgopEK4i62t9sqyqCBckq3IJgA6EAoQBYIC9gPmCdKyqwj9RiAaeSsUI7zPKDZS+CjoN+sfihk/5VBPY="

        nonisolated(unsafe) static let remoteUserClient = WireAPI.UserClient(
            id: userClientID,
            type: .permanent,
            activationDate: .now,
            label: "test",
            model: "test",
            deviceClass: .phone,
            capabilities: []
        )

        nonisolated(unsafe) static let legalHoldRequest = LegalHoldRequest(
            target: userID,
            requester: nil,
            clientIdentifier: userClientID,
            lastPrekey: .init(
                id: lastPrekeyId,
                key: Data(base64Encoded: base64encodedString)!
            )
        )

        static let user1 = User(
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

        static let conversationLabel1 = ConversationLabel(
            id: UUID(uuidString: "f3d302fb-3fd5-43b2-927b-6336f9e787b0")!,
            name: "ConversationLabel1",
            type: 0,
            conversationIDs: [
                UUID(uuidString: "ffd0a9af-c0d0-4748-be9b-ab309c640dde")!,
                UUID(uuidString: "03fe0d05-f0d5-4ee4-a8ff-8d4b4dcf89d8")!
            ]
        )

        static let conversationLabel2 = ConversationLabel(
            id: UUID(uuidString: "2AA27182-AA54-4D79-973E-8974A3BBE375")!,
            name: "ConversationLabel2",
            type: 0,
            conversationIDs: [
                UUID(uuidString: "ceb3f577-3b22-4fe9-8ffd-757f29c47ffc")!,
                UUID(uuidString: "eca55fdb-8f81-4112-9175-4ffca7691bf8")!
            ]
        )
    }

}
