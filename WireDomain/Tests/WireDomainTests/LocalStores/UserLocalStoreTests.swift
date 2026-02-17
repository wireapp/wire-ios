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

final class UserLocalStoreTests: XCTestCase {

    private var sut: UserLocalStore!
    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!
    private var mockUserDefaults: UserDefaults!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        coreDataStackHelper = CoreDataStackHelper()
        modelHelper = ModelHelper()
        stack = try await coreDataStackHelper.createStack()

        mockUserDefaults = UserDefaults(
            suiteName: Scaffolding.defaultsTestSuiteName
        )

        conversationLocalStore = MockConversationLocalStoreProtocol()

        sut = UserLocalStore(
            context: context,
            messageLocalStore: MockMessageLocalStoreProtocol(),
            userDefaults: mockUserDefaults
        )
    }

    override func tearDown() async throws {
        stack = nil
        sut = nil
        mockUserDefaults.removePersistentDomain(
            forName: Scaffolding.defaultsTestSuiteName
        )
        mockUserDefaults = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        modelHelper = nil
        conversationLocalStore = nil
    }

    // MARK: - Tests

    func testPersistUser_It_Stores_User_Locally() async throws {
        // Mock

        await context.perform { [context] in
            // There is no user in the database.
            XCTAssertNil(ZMUser.fetch(
                with: Scaffolding.userInfo.userID.uuid,
                domain: Scaffolding.userInfo.userID.domain,
                in: context
            ))
        }

        // When

        await sut.persistUser(userInfo: Scaffolding.userInfo)

        // Then
        try await context.perform { [context] in
            // There is a user in the database.
            let user = try XCTUnwrap(
                ZMUser.fetch(
                    with: Scaffolding.userInfo.userID.uuid,
                    domain: Scaffolding.userInfo.userID.domain,
                    in: context
                )
            )
            XCTAssertEqual(user.remoteIdentifier, Scaffolding.userInfo.userID.uuid)
            XCTAssertEqual(user.name, Scaffolding.userInfo.name)
            XCTAssertEqual(user.handle, Scaffolding.userInfo.handle)
            XCTAssertEqual(user.teamIdentifier, Scaffolding.userInfo.teamID)
            XCTAssertEqual(user.accentColorValue, Int16(Scaffolding.userInfo.accentID))
            XCTAssertEqual(user.isAccountDeleted, Scaffolding.userInfo.isDeleted)
            XCTAssertEqual(user.emailAddress, Scaffolding.userInfo.email)
            XCTAssertEqual(user.supportedProtocols, Scaffolding.userInfo.supportedProtocols)
            XCTAssertFalse(user.needsToBeUpdatedFromBackend)
        }
    }

    func testDeletePushToken_It_Removes_Token_From_Defaults() async throws {
        // Mock

        let key = "PushToken"
        let data = try JSONEncoder().encode(Scaffolding.pushToken)
        mockUserDefaults.set(data, forKey: key)
        XCTAssertNotNil(mockUserDefaults.object(forKey: key))

        // When

        sut.deletePushToken()

        // Then

        let pushToken = mockUserDefaults.object(forKey: key)
        XCTAssertNil(pushToken)
    }

    func testFetchSelfUser_It_Retrieves_Self_User_Locally() async {
        // Mock

        let selfUser = await context.perform { [self] in
            modelHelper.createSelfUser(
                id: Scaffolding.userID,
                domain: nil,
                in: context
            )
        }

        // When

        let localSelfUser = await sut.fetchSelfUser()

        // Then

        await context.perform {
            XCTAssertEqual(selfUser, localSelfUser)
        }
    }

    func testFetchUser_It_Retrieves_User_Locally() async throws {
        // Mock

        let user = await context.perform { [self] in
            modelHelper.createUser(
                id: Scaffolding.userID,
                domain: nil,
                in: context
            )
        }

        // When

        let localUser = try await sut.fetchUser(
            id: Scaffolding.userID,
            domain: nil
        )

        // Then

        await context.perform {
            XCTAssertEqual(user, localUser)
        }
    }

    func testAddSelfLegalholdRequest_It_Sets_Status_To_Pending_With_Legal_Hold_Request() async throws {
        // Mock

        _ = await context.perform { [self] in
            modelHelper.createSelfUser(
                id: Scaffolding.userID,
                domain: nil,
                in: context
            )
        }

        // When

        await sut.addSelfLegalHoldRequest(
            userID: Scaffolding.userID,
            clientID: Scaffolding.userClientID,
            lastPrekey: .init(
                id: Scaffolding.lastPrekeyId,
                key: try XCTUnwrap(Data(base64Encoded: Scaffolding.base64encodedString))
            )
        )

        // Then

        try await context.perform { [context] in
            let selfUser = try XCTUnwrap(ZMUser.fetch(with: Scaffolding.userID, in: context))

            XCTAssertEqual(selfUser.legalHoldStatus, .pending(Scaffolding.legalHoldRequest))
        }
    }

    func testPostAccountDeletedNotification_It_Posts_Account_Deleted_Notification() async {
        // Given

        let expectation = XCTestExpectation()
        let notificationName = AccountDeletedNotification.notificationName

        NotificationCenter.default.addObserver(
            forName: notificationName,
            object: nil,
            queue: nil
        ) { notification in

            // Then
            XCTAssertNotNil(notification.userInfo?[notificationName] as? AccountDeletedNotification)

            expectation.fulfill()
        }

        // When

        sut.postAccountDeletedNotification()

        // Then

        await fulfillment(of: [expectation], timeout: 1)
    }

    func testMarkAccountAsDeleted_It_Sets_Is_Account_Deleted_Flag_To_True() async {
        // Mock

        let user = await context.perform { [self] in
            modelHelper.createUser(
                id: Scaffolding.userID,
                domain: nil,
                in: context
            )
        }

        // When

        await sut.markAccountAsDeleted(for: user)

        // Then

        await context.perform {
            XCTAssertEqual(user.isAccountDeleted, true)
        }
    }

    func testUpdateSelfUserReadReceipts_It_Enables_Read_Receipts_Property() async {
        // Mock

        let selfUser = await context.perform { [self] in
            let selfUser = modelHelper.createSelfUser(
                id: Scaffolding.userID,
                domain: nil,
                in: context
            )

            selfUser.readReceiptsEnabled = false
            selfUser.readReceiptsEnabledChangedRemotely = false

            return selfUser
        }

        // When

        await sut.updateSelfUserReadReceipts(
            isReadReceiptsEnabled: true,
            isReadReceiptsEnabledChangedRemotely: true
        )

        // Then

        await context.perform {
            XCTAssertEqual(selfUser.readReceiptsEnabled, true)
            XCTAssertEqual(selfUser.readReceiptsEnabledChangedRemotely, true)
        }
    }

    func testUpdateUser_It_Updates_User_Locally() async throws {
        // Given

        _ = await context.perform { [self] in
            modelHelper.createUser(
                id: Scaffolding.userID,
                handle: Scaffolding.existingHandle,
                email: Scaffolding.existingEmail,
                supportedProtocols: [.mls],
                in: context
            )
        }

        // When

        await sut.updateUser(userUpdateInfo: Scaffolding.userUpdateInfo)

        // Then

        try await context.perform { [context] in
            let updatedUser = try XCTUnwrap(ZMUser.fetch(with: Scaffolding.userID, in: context))

            XCTAssertEqual(updatedUser.remoteIdentifier, Scaffolding.userID)
            XCTAssertEqual(updatedUser.name, Scaffolding.userUpdateInfo.name)
            XCTAssertEqual(updatedUser.handle, Scaffolding.existingHandle) /// ensuring handle is not updated to nil
            XCTAssertEqual(updatedUser.emailAddress, Scaffolding.existingEmail) /// ensuring email is not updated to nil
            XCTAssertEqual(updatedUser.supportedProtocols, [.proteus, .mls])
        }
    }

    func testUpdateUserAvailability() async throws {
        // Mock
        let selfUser = await context.perform { [self] in
            return modelHelper.createSelfUser(id: Scaffolding.selfUserID, in: context)
        }

        // When
        await sut.updateUser(
            with: QualifiedID(uuid: Scaffolding.selfUserID, domain: Scaffolding.domain),
            availability: .available
        )

        // Then
        await context.perform {
            XCTAssertEqual(selfUser.availability, .available)
        }
    }

    func testIsSelfUser_It_Returns_Correct_Flag() async throws {
        // Mock

        let (selfUser, notSelfUser) = await context.perform { [self] in
            let selfUser = modelHelper.createSelfUser(id: Scaffolding.selfUserID, in: context)
            let notSelfUser = modelHelper.createUser(id: Scaffolding.userID, in: context)

            return (selfUser, notSelfUser)
        }

        // When / Then isSelfUser == true

        let (user, isSelfUser) = try await sut.isSelfUser(
            id: Scaffolding.selfUserID,
            domain: nil
        )

        XCTAssertEqual(user, selfUser)
        XCTAssertEqual(isSelfUser, true)

        // When / Then isSelfUser2 == false

        let (user2, isSelfUser2) = try await sut.isSelfUser(
            id: Scaffolding.userID,
            domain: nil
        )

        XCTAssertEqual(user2, notSelfUser)
        XCTAssertEqual(isSelfUser2, false)
    }

    private enum Scaffolding {

        static let selfUserID = UUID.mockID1
        static let userID = UUID.mockID2
        static let domain = "domain.com"
        static let existingHandle = "handle"
        static let existingEmail = "test@wire.com"
        static let userClientID = UUID.mockID4.uuidString
        static let lastPrekeyId = 65_535
        static let base64encodedString =
            "pQABAQoCoQBYIPEFMBhOtG0dl6gZrh3kgopEK4i62t9sqyqCBckq3IJgA6EAoQBYIC9gPmCdKyqwj9RiAaeSsUI7zPKDZS+CjoN+sfihk/5VBPY="

        nonisolated(unsafe) static let legalHoldRequest = LegalHoldRequest(
            target: userID,
            requester: nil,
            clientIdentifier: userClientID,
            lastPrekey: .init(
                id: lastPrekeyId,
                key: Data(base64Encoded: base64encodedString)!
            )
        )

        static let userInfo = NewUserInfo(
            userID: QualifiedID(uuid: userID, domain: domain),
            name: "user1",
            handle: "handle1",
            teamID: nil,
            type: .regular,
            accentID: 1,
            previewAssetKey: nil,
            completeAssetKey: nil,
            isDeleted: false,
            email: "john.doe@example.com",
            expiresAt: .now,
            serviceID: nil,
            serviceProvider: nil,
            supportedProtocols: [.mls]
        )

        static let userUpdateInfo = UserUpdateInfo(
            userID: userID,
            accentColorID: nil,
            name: "username",
            handle: nil,
            email: nil,
            isSSOIDDeleted: nil,
            previewAssetKey: nil,
            completeAssetKey: nil,
            supportedProtocols: [.proteus, .mls]
        )

        static let deviceToken = Data(repeating: 0x41, count: 10)

        nonisolated(unsafe) static let pushToken = PushToken(
            deviceToken: deviceToken,
            appIdentifier: "com.wire",
            transportType: "APNS_VOIP"
        )

        static let defaultsTestSuiteName = UUID.mockID1.uuidString

    }

}
