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

import WireDataModel
import WireDataModelSupport
import WireDomainSupport
import WireNetworkSupport
import WireTestingPackage
import XCTest
@testable import WireDomain
@testable import WireNetwork

final class UserRepositoryTests: XCTestCase {

    private var sut: UserRepository!
    private var usersAPI: MockUsersAPI!
    private var selfUsersAPI: MockSelfUserAPI!
    private var userLocalStore: MockUserLocalStoreProtocol!
    private var conversationLabelsRepository: MockConversationLabelsRepositoryProtocol!
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
        usersAPI = MockUsersAPI()
        selfUsersAPI = MockSelfUserAPI()
        conversationLabelsRepository = MockConversationLabelsRepositoryProtocol()
        userLocalStore = MockUserLocalStoreProtocol()

        sut = UserRepository(
            usersAPI: usersAPI,
            selfUserAPI: selfUsersAPI,
            conversationLabelsRepository: conversationLabelsRepository,
            userLocalStore: userLocalStore
        )
    }

    override func tearDown() async throws {
        stack = nil
        usersAPI = nil
        selfUsersAPI = nil
        userLocalStore = nil
        conversationLabelsRepository = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        modelHelper = nil
    }

    // MARK: - Tests

    func testPullUsers_It_Invokes_Local_Store_Method() async throws {
        // Given

        await context.perform { [context] in
            // There is no user in the database.
            XCTAssertNil(ZMUser.fetch(
                with: Scaffolding.user1.id.id,
                domain: Scaffolding.user1.id.domain,
                in: context
            ))
        }

        // Mock

        usersAPI.getUsersUserIDs_MockValue = WireNetwork.UserList(
            found: [Scaffolding.user1],
            failed: []
        )

        userLocalStore.persistUserUserInfo_MockMethod = { _ in }

        // When

        try await sut.pullUsers(userIDs: [Scaffolding.user1.id.toDomainModel()])

        // Then

        XCTAssertEqual(userLocalStore.persistUserUserInfo_Invocations.count, 1)
    }

    func testPullKnownUsers_It_Invokes_Local_Store_Methods() async throws {
        // Given

        _ = await context.perform { [context] in
            // Insert incomplete user in the database.
            ZMUser.fetchOrCreate(with: Scaffolding.user1.id.id, domain: Scaffolding.user1.id.domain, in: context)
        }

        // Mock

        usersAPI.getUsersUserIDs_MockValue = WireNetwork.UserList(
            found: [Scaffolding.user1],
            failed: []
        )

        userLocalStore.fetchUsersQualifiedIDs_MockValue = [Scaffolding.user1.id.toDomainModel()]
        userLocalStore.persistUserUserInfo_MockMethod = { _ in }

        // When

        try await sut.pullKnownUsers()

        // Then

        XCTAssertEqual(userLocalStore.fetchUsersQualifiedIDs_Invocations.count, 1)
        XCTAssertEqual(userLocalStore.persistUserUserInfo_Invocations.count, 1)
    }

    func testRemovesPushToken_It_Invokes_Local_Store_Method() {
        // Mock

        userLocalStore.deletePushToken_MockMethod = {}

        // When

        sut.removePushToken()

        // Then

        XCTAssertEqual(userLocalStore.deletePushToken_Invocations.count, 1)
    }

    func testFetchSelfUser_It_Invokes_Local_Store_Method() async {
        // Mock

        let selfUser = await context.perform { [self] in
            modelHelper.createSelfUser(
                id: .mockID1,
                domain: nil,
                in: context
            )
        }

        userLocalStore.fetchSelfUser_MockValue = selfUser

        // When

        let localSelfUser = await sut.fetchSelfUser()

        // Then

        XCTAssertEqual(localSelfUser, selfUser)
        XCTAssertEqual(userLocalStore.fetchSelfUser_Invocations.count, 1)
    }

    func testFetchUser_It_Invokes_Local_Store_Method() async throws {
        // Mock

        let user = await context.perform { [self] in
            modelHelper.createUser(
                id: .mockID1,
                domain: nil,
                in: context
            )
        }

        userLocalStore.fetchUserIdDomain_MockValue = user

        // When

        let localUser = try await sut.fetchUser(
            id: .mockID1,
            domain: nil
        )

        // Then

        XCTAssertEqual(localUser, user)
        XCTAssertEqual(userLocalStore.fetchUserIdDomain_Invocations.count, 1)
    }

    func testAddLegalholdRequest_It_Invokes_Local_Store_Method() async {
        // Mock

        userLocalStore.addSelfLegalHoldRequestUserIDClientIDLastPrekey_MockMethod = { _, _, _ in }

        // When

        await sut.addLegalHoldRequest(
            userID: .mockID1,
            clientID: UUID().uuidString,
            lastPrekey: Prekey(
                id: Scaffolding.lastPrekeyId,
                base64EncodedKey: Scaffolding.base64encodedString
            )
        )

        // Then

        XCTAssertEqual(userLocalStore.addSelfLegalHoldRequestUserIDClientIDLastPrekey_Invocations.count, 1)
    }

    func testDeleteUserAccountForSelfUser_It_Invokes_Local_Store_Methods() async throws {
        // Mock

        let selfUser = await context.perform { [self] in
            return modelHelper.createSelfUser(
                id: .mockID1,
                in: context
            )
        }

        userLocalStore.isSelfUserIdDomain_MockValue = (selfUser, true)
        userLocalStore.postAccountDeletedNotification_MockMethod = {}

        // When

        try await sut.deleteUserAccount(
            id: .mockID1,
            domain: nil,
            at: .now
        )

        // Then

        XCTAssertEqual(userLocalStore.isSelfUserIdDomain_Invocations.count, 1)
        XCTAssertEqual(userLocalStore.postAccountDeletedNotification_Invocations.count, 1)
    }

    func testDeleteUserAccountForNotSelfUser_It_Invokes_Local_Store_And_Conversation_Repo_Methods() async throws {
        // Mock

        let user = await context.perform { [self] in
            return modelHelper.createUser(
                id: .mockID1,
                in: context
            )
        }

        userLocalStore.isSelfUserIdDomain_MockValue = (user, false)
        userLocalStore.markAccountAsDeletedFor_MockMethod = { _ in }
        userLocalStore.removeUserFromAllConversationsIdDomainDate_MockMethod = { _, _, _ in }

        // When

        try await sut.deleteUserAccount(
            id: .mockID1,
            domain: nil,
            at: .now
        )

        // Then

        XCTAssertEqual(userLocalStore.isSelfUserIdDomain_Invocations.count, 1)
        XCTAssertEqual(userLocalStore.markAccountAsDeletedFor_Invocations.count, 1)

        XCTAssertEqual(
            userLocalStore
                .removeUserFromAllConversationsIdDomainDate_Invocations.count,
            1
        )
    }

    func testUpdateUserProperty_It_Enables_Read_Receipts_Property_It_Invokes_Local_Store_Method() async throws {
        // Mock

        userLocalStore
            .updateSelfUserReadReceiptsIsReadReceiptsEnabledIsReadReceiptsEnabledChangedRemotely_MockMethod = { _, _ in
            }

        // When

        try await sut.updateUserProperty(.areReadReceiptsEnabled(true))

        // Then

        XCTAssertEqual(
            userLocalStore
                .updateSelfUserReadReceiptsIsReadReceiptsEnabledIsReadReceiptsEnabledChangedRemotely_Invocations.count,
            1
        )
    }

    func testUpdateUserProperty_It_Invokes_Conversation_Labels_Repo_Method() async throws {
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

        conversationLabelsRepository.updateConversationLabels_MockError = ConversationLabelsRepositoryError
            .failedToDeleteStoredLabels

        // Then

        await XCTAssertThrowsErrorAsync(
            ConversationLabelsRepositoryError.failedToDeleteStoredLabels
        ) { [self] in

            // When

            try await sut.updateUserProperty(
                .conversationLabels([Scaffolding.conversationLabel1, Scaffolding.conversationLabel2])
            )
        }
    }

    func testUpdateUser_It_Updates_User_Locally_It_Invokes_Local_Store_Method() async {
        // Mock

        userLocalStore.updateUserUserUpdateInfo_MockMethod = { _ in }

        // When

        await sut.updateUser(from: Scaffolding.event)

        // Then

        XCTAssertEqual(userLocalStore.updateUserUserUpdateInfo_Invocations.count, 1)
    }

    func testIsSelfUser_It_Invokes_Local_Store_Method() async throws {
        // Mock

        let user = await context.perform { [self] in
            return modelHelper.createSelfUser(
                id: .mockID1,
                in: context
            )
        }

        userLocalStore.isSelfUserIdDomain_MockValue = (user, true)

        // When

        _ = try await sut.isSelfUser(
            id: .mockID1,
            domain: Scaffolding.domain
        )

        // Then

        XCTAssertEqual(userLocalStore.isSelfUserIdDomain_Invocations.count, 1)
    }

    func testPullSelfUser_It_Invokes_Local_Store_Methods() async throws {
        // Mock
        selfUsersAPI.getSelfUser_MockValue = Scaffolding.selfUser
        userLocalStore.persistUserUserInfo_MockMethod = { _ in }

        // When

        try await sut.pullSelfUser()

        // Then

        XCTAssertEqual(selfUsersAPI.getSelfUser_Invocations.count, 1)
        XCTAssertEqual(userLocalStore.persistUserUserInfo_Invocations.count, 1)
    }

    func testFetchAllUserIdsWithOneOnOneConversation_It_Invokes_Local_Store_Method() async throws {
        // Given

        userLocalStore.fetchAllUserIDsWithOneOnOneConversation_MockValue = [Scaffolding.qualifiedID.toDomainModel()]

        // When

        let userIds = try await sut.fetchAllUserIDsWithOneOnOneConversation()

        // Then

        XCTAssertEqual(userLocalStore.fetchAllUserIDsWithOneOnOneConversation_Invocations.count, 1)
        XCTAssertEqual(userIds, [Scaffolding.qualifiedID.toDomainModel()])
    }

    func testFetchAllUserIdsWithOneOnOneConversation() async throws {
        // Given

        userLocalStore.fetchAllUserIDsWithOneOnOneConversation_MockValue = [Scaffolding.qualifiedID.toDomainModel()]

        // When

        let userIds = try await sut.fetchAllUserIDsWithOneOnOneConversation()

        // Then

        XCTAssertEqual(userLocalStore.fetchAllUserIDsWithOneOnOneConversation_Invocations.count, 1)
        XCTAssertEqual(userIds, [Scaffolding.qualifiedID.toDomainModel()])
    }

    private enum Scaffolding {

        static let domain = "domain.com"

        static let lastPrekeyId = 65_535

        static let base64encodedString =
            "pQABAQoCoQBYIPEFMBhOtG0dl6gZrh3kgopEK4i62t9sqyqCBckq3IJgA6EAoQBYIC9gPmCdKyqwj9RiAaeSsUI7zPKDZS+CjoN+sfihk/5VBPY="

        static let qualifiedID = UserID(id: UUID(), domain: "example.com")

        static let conversationLabel1 = ConversationLabel(
            id: .mockID1,
            name: "ConversationLabel1",
            type: 0,
            conversationIDs: [
                .mockID2,
                .mockID3
            ]
        )

        static let conversationLabel2 = ConversationLabel(
            id: .mockID1,
            name: "ConversationLabel2",
            type: 0,
            conversationIDs: [
                .mockID2,
                .mockID3
            ]
        )

        nonisolated(unsafe) static let legalHoldRequest = LegalHoldRequest(
            target: .mockID1,
            requester: nil,
            clientIdentifier: UUID().uuidString,
            lastPrekey: .init(
                id: lastPrekeyId,
                key: Data(base64Encoded: base64encodedString)!
            )
        )

        static let user1 = User(
            id: QualifiedID(id: .mockID1, domain: domain),
            name: "user1",
            handle: "handle1",
            teamID: nil,
            type: .regular,
            accentID: 1,
            assets: [],
            deleted: false,
            email: "john.doe@example.com",
            expiresAt: nil,
            service: nil,
            supportedProtocols: [.mls],
            legalholdStatus: .disabled
        )

        static let selfUser = SelfUser(
            id: qualifiedID.id,
            qualifiedID: qualifiedID,
            ssoID: nil,
            name: "username",
            handle: "username",
            teamID: UUID(),
            phone: "",
            accentID: 1,
            managedBy: .wire,
            assets: [],
            deleted: false,
            email: "username@wire.com",
            expiresAt: .now,
            service: nil,
            supportedProtocols: [.mls]
        )

        static let event = UserUpdateEvent(
            userID: .mockID1,
            accentColorID: nil,
            name: "username",
            handle: nil,
            email: nil,
            isSSOIDDeleted: nil,
            assets: nil,
            supportedProtocols: [.proteus, .mls]
        )

        static let pushToken = PushToken(
            deviceToken: Data(repeating: 0x41, count: 10),
            appIdentifier: "com.wire",
            transportType: "APNS_VOIP"
        )

    }

}
