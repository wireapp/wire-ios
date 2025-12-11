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

import WireUtilities
import XCTest

@testable import WireDataModel
@testable import WireDataModelSupport

final class UserClientTests: ZMBaseManagedObjectTest {

    func clientWithTrustedClientCount(
        _ trustedCount: UInt,
        ignoredClientCount: UInt,
        missedClientCount: UInt
    ) -> UserClient {
        let client = UserClient.insertNewObject(in: uiMOC)

        func userClientSetWithClientCount(_ count: UInt) -> Set<UserClient>? {
            guard count != 0 else { return nil }

            var clients = Set<UserClient>()
            for _ in 0 ..< count {
                clients.insert(UserClient.insertNewObject(in: uiMOC))
            }
            return clients
        }

        let trustedClient = userClientSetWithClientCount(trustedCount)
        let ignoredClient = userClientSetWithClientCount(ignoredClientCount)
        let missedClient = userClientSetWithClientCount(missedClientCount)

        if let trustedClient { client.trustedClients = trustedClient }
        if let ignoredClient { client.ignoredClients = ignoredClient }
        client.missingClients = missedClient

        return client
    }

    func testThatItCanInitializeClient() {
        let client = UserClient.insertNewObject(in: uiMOC)
        XCTAssertEqual(client.type, .permanent, "Client type should be 'permanent'")
    }

    func testThatClientsAreNotDuplicatedInCoreData() throws {
        let remoteIdentifier = "unique-client"

        let client1 = UserClient.insertNewObject(in: uiMOC)
        client1.remoteIdentifier = remoteIdentifier

        let client2 = UserClient.insertNewObject(in: uiMOC)
        client2.remoteIdentifier = remoteIdentifier

        uiMOC.saveOrRollback()

        let fetchRequest = NSFetchRequest<UserClient>(entityName: UserClient.entityName())
        fetchRequest.predicate = NSPredicate(format: "%K == %@", ZMUserClientRemoteIdentifierKey, remoteIdentifier)
        fetchRequest.fetchLimit = 2

        let result = try uiMOC.fetch(fetchRequest)

        XCTAssertEqual(result.count, 1, "There should be only one client with remote identifier \(remoteIdentifier)")
    }

    func testThatItReturnsTrackedKeys() {
        let client = UserClient.insertNewObject(in: uiMOC)
        let trackedKeys = client.keysTrackedForLocalModifications()
        XCTAssertTrue(trackedKeys.contains(ZMUserClientMarkedToDeleteKey), "")
        XCTAssertTrue(trackedKeys.contains(ZMUserClientNumberOfKeysRemainingKey), "")
    }

    func testThatItSyncClientsWithNoRemoteIdentifier() {
        let unsyncedClient = UserClient.insertNewObject(in: uiMOC)
        let syncedClient = UserClient.insertNewObject(in: uiMOC)
        syncedClient.remoteIdentifier = "synced"

        XCTAssertTrue(UserClient.predicateForObjectsThatNeedToBeInsertedUpstream()!.evaluate(with: unsyncedClient))
        XCTAssertFalse(UserClient.predicateForObjectsThatNeedToBeInsertedUpstream()!.evaluate(with: syncedClient))
    }

    func testThatClientCanBeMarkedForDeletion() {
        let client = UserClient.insertNewObject(in: uiMOC)
        client.user = ZMUser.selfUser(in: uiMOC)

        XCTAssertFalse(client.markedToDelete)
        client.markForDeletion()

        XCTAssertTrue(client.markedToDelete)
        XCTAssertTrue(client.hasLocalModifications(forKey: ZMUserClientMarkedToDeleteKey))
    }

    func testThatItTracksCorrectKeys() {
        let expectedKeys = Set([
            ZMUserClientMarkedToDeleteKey,
            ZMUserClientNumberOfKeysRemainingKey,
            ZMUserClientMissingKey,
            ZMUserClientNeedsToUpdateCapabilitiesKey,
            UserClient.needsToUploadMLSPublicKeysKey
        ])

        let client = UserClient.insertNewObject(in: uiMOC)
        XCTAssertEqual(client.keysTrackedForLocalModifications(), expectedKeys)
    }

    func testThatTrustingClientsRemovesThemFromIgnoredClientList() {

        let client = clientWithTrustedClientCount(0, ignoredClientCount: 2, missedClientCount: 0)

        let ignoredClient = client.ignoredClients.first!

        client.trustClients([ignoredClient])

        XCTAssertFalse(client.ignoredClients.contains(ignoredClient))
        XCTAssertTrue(client.trustedClients.contains(ignoredClient))
    }

    func testThatIgnoringClientsRemovesThemFromTrustedList() {

        let client = clientWithTrustedClientCount(2, ignoredClientCount: 1, missedClientCount: 0)

        let trustedClient = client.trustedClients.first!

        client.ignoreClients([trustedClient])

        XCTAssertFalse(client.trustedClients.contains(trustedClient))
        XCTAssertTrue(client.ignoredClients.contains(trustedClient))
    }

    func testThatTrustingClientsRemovesTheNeedToNotifyUser() {
        // Given
        let client = clientWithTrustedClientCount(0, ignoredClientCount: 1, missedClientCount: 0)
        let ignoredClient = client.ignoredClients.first!
        ignoredClient.needsToNotifyUser = true

        // When
        client.trustClient(ignoredClient)

        // Then
        XCTAssertFalse(ignoredClient.needsToNotifyUser)
    }

    func testThatItDeletesASession() async throws {
        // Given
        var otherClient: UserClient!
        let mockProteusService = MockProteusServiceInterface()
        mockProteusService.deleteSessionId_MockMethod = { _ in
            // No op
        }

        await syncMOC.performGrouped {
            otherClient = UserClient.insertNewObject(in: self.syncMOC)
            otherClient.remoteIdentifier = UUID.create().transportString()
            otherClient.user = ZMUser.insertNewObject(in: self.syncMOC)
            otherClient.user?.remoteIdentifier = UUID.create()

            self.syncMOC.proteusService = mockProteusService
        }

        // When
        try await otherClient.deleteSession()

        // Then
        await syncMOC.performGrouped {
            XCTAssertEqual(mockProteusService.deleteSessionId_Invocations, [otherClient.proteusSessionID])
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItDeletesASessionWhenDeletingAClient() async {
        // Given
        var otherClient: UserClient!
        var otherClientSessionID: ProteusSessionID!
        let mockProteusService = MockProteusServiceInterface()
        mockProteusService.deleteSessionId_MockMethod = { _ in
            // No op
        }

        await syncMOC.performGrouped {
            otherClient = UserClient.insertNewObject(in: self.syncMOC)
            otherClient.remoteIdentifier = UUID.create().transportString()
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            otherClient.user = otherUser
            otherClientSessionID = otherClient.proteusSessionID
            self.syncMOC.proteusService = mockProteusService
        }

        // When
        await otherClient.deleteClientAndEndSession()

        // Then
        XCTAssertEqual(mockProteusService.deleteSessionId_Invocations, [otherClientSessionID])

        await syncMOC.performGrouped {
            XCTAssertTrue(otherClient.isZombieObject)
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItUpdatesConversationSecurityLevelWhenDeletingClient() async {
        // given
        var otherUser: ZMUser!
        var otherClient2: UserClient!
        var conversation: ZMConversation!

        await syncMOC.performGrouped {
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)

            let otherClient1 = UserClient.insertNewObject(in: self.syncMOC)
            otherClient1.remoteIdentifier = UUID.create().transportString()

            otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            otherClient1.user = otherUser
            let connection = ZMConnection.insertNewSentConnection(to: otherUser)
            connection.status = .accepted

            conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .group

            conversation.addParticipantsAndUpdateConversationState(
                users: Set([otherUser, ZMUser.selfUser(in: self.syncMOC)]),
                role: nil
            )

            selfClient.trustClient(otherClient1)

            conversation.securityLevel = ZMConversationSecurityLevel.notSecure
            XCTAssertEqual(conversation.allMessages.count, 1)

            otherClient2 = UserClient.insertNewObject(in: self.syncMOC)
            otherClient2.remoteIdentifier = UUID.create().transportString()
            otherClient2.user = otherUser

            selfClient.ignoreClient(otherClient2)
        }

        // when
        await otherClient2.deleteClientAndEndSession()
        _ = await syncMOC.perform { [syncMOC] in syncMOC.saveOrRollback() }

        // then
        await syncMOC.performGrouped {
            XCTAssertTrue(otherClient2.isZombieObject)
            XCTAssertEqual(conversation.securityLevel, ZMConversationSecurityLevel.secure)
            XCTAssertEqual(conversation.allMessages.count, 2)
            if let message = conversation.lastMessage as? ZMSystemMessage {
                XCTAssertEqual(message.systemMessageType, ZMSystemMessageType.conversationIsSecure)
                XCTAssertEqual(message.users, [otherUser])
            } else {
                XCTFail("Did not insert systemMessage")
            }
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatWhenDeletingClientItTriggersUserFetchForPossibleMemberLeave() async {
        // given
        var otherUser: ZMUser!
        var otherClient: UserClient!

        await syncMOC.performGrouped {
            otherClient = UserClient.insertNewObject(in: self.syncMOC)
            otherClient.remoteIdentifier = UUID.create().transportString()

            otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            otherClient.user = otherUser

            let team = self.createTeam(in: self.syncMOC)
            _ = self.createMembership(in: self.syncMOC, user: otherUser, team: team)

            otherUser.needsToBeUpdatedFromBackend = false

            XCTAssertTrue(otherUser.isTeamMember)
            XCTAssertFalse(otherUser.needsToBeUpdatedFromBackend)
        }

        // when
        await otherClient.deleteClientAndEndSession()

        // then
        await syncMOC.performGrouped {
            XCTAssertTrue(otherClient.isZombieObject)
            XCTAssertTrue(otherUser.clients.isEmpty)
            XCTAssertTrue(otherUser.needsToBeUpdatedFromBackend)
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func testThatItSetsNeedsToNotifyOtherUserAboutSessionReset_WhenResettingSession() {
        var otherClient: UserClient!

        // given
        syncMOC.performGroupedAndWait {
            _ = self.createSelfClient(onMOC: self.syncMOC)

            otherClient = UserClient.insertNewObject(in: self.syncMOC)
            otherClient.remoteIdentifier = UUID.create().transportString()

            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            otherClient.user = otherUser

            let connection = ZMConnection.insertNewSentConnection(to: otherUser)
            connection.status = .accepted
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        syncMOC.performGroupedAndWait {
            otherClient.resetSession()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        syncMOC.performGroupedAndWait {
            XCTAssertTrue(otherClient.needsToNotifyOtherUserAboutSessionReset)
        }
    }

    func testThatItAsksForMoreWhenRunningOutOfPrekeys() {

        syncMOC.performGroupedAndWait {
            // given
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)
            selfClient.numberOfKeysRemaining = 1

            // when
            selfClient.decrementNumberOfRemainingProteusKeys()

            // then
            XCTAssertTrue(selfClient.modifiedKeys!.contains(ZMUserClientNumberOfKeysRemainingKey))
        }
    }

    func testThatItDoesntAskForMoreWhenItStillHasPrekeys() {

        syncMOC.performGroupedAndWait {
            // given
            let selfClient = self.createSelfClient(onMOC: self.syncMOC)
            selfClient.numberOfKeysRemaining = 2

            // when
            selfClient.decrementNumberOfRemainingProteusKeys()

            // then
            XCTAssertNil(selfClient.modifiedKeys)
        }
    }
}

extension UserClientTests {
    func testThatItStoresFailedToEstablishSessionInformation() {
        syncMOC.performGroupedAndWait {
            // given
            let client = UserClient.insertNewObject(in: self.syncMOC)

            // when & then
            XCTAssertFalse(client.failedToEstablishSession)

            // when
            client.failedToEstablishSession = true

            // then
            XCTAssertTrue(client.failedToEstablishSession)

            // when
            client.failedToEstablishSession = false

            // then
            XCTAssertFalse(client.failedToEstablishSession)
        }
    }
}

extension UserClientTests {

    func testThatSelfClientIsTrusted() {
        // given & when
        let selfClient = createSelfClient()

        // then
        XCTAssertTrue(selfClient.verified)
    }

    func testThatSelfClientIsStillVerifiedAfterIgnoring() {
        // given
        let selfClient = createSelfClient()

        // when
        selfClient.ignoreClient(selfClient)

        // then
        XCTAssertTrue(selfClient.verified)
    }

    func testThatUnknownClientIsNotVerified() {
        // given & when
        createSelfClient()

        let otherClient = UserClient.insertNewObject(in: uiMOC)
        otherClient.remoteIdentifier = .randomRemoteIdentifier()

        // then
        XCTAssertFalse(otherClient.verified)
    }

    func testThatItIsVerifiedWhenTrusted() {
        // given
        let selfClient = createSelfClient()

        let otherClient = UserClient.insertNewObject(in: uiMOC)
        otherClient.remoteIdentifier = .randomRemoteIdentifier()

        // when
        selfClient.trustClient(otherClient)

        // then
        XCTAssertTrue(otherClient.verified)
    }

    func testThatItIsNotVerifiedWhenIgnored() {
        // given
        let selfClient = createSelfClient()

        let otherClient = UserClient.insertNewObject(in: uiMOC)
        otherClient.remoteIdentifier = .randomRemoteIdentifier()

        // when
        selfClient.ignoreClient(otherClient)

        // then
        XCTAssertFalse(otherClient.verified)
    }
}

// MARK: Capabilities

extension UserClientTests {

    func testThatItSetsKeysNeedingToBeSynced_Capabilities() {
        // given
        let selfClient = createSelfClient()

        // when
        UserClient.triggerSelfClientCapabilityUpdate(uiMOC)

        // then
        XCTAssertTrue(selfClient.needsToUpdateCapabilities)
        XCTAssertTrue(selfClient.keysThatHaveLocalModifications.contains(ZMUserClientNeedsToUpdateCapabilitiesKey))
    }

}

// MARK: fetchFingerprintOrPrekeys

extension UserClientTests {

    func testThatItSetsTheUserWhenInsertingANewSelfUserClient() {
        // given
        _ = createSelfClient()
        let newClientPayload: [String: AnyObject] = [
            "id": UUID().transportString() as AnyObject,
            "type": "permanent" as AnyObject,
            "time": Date().transportString() as AnyObject,
            "mls_public_keys": ["ed25519": "some key"] as AnyObject
        ]

        // when
        var newClient: UserClient!
        performPretendingUiMocIsSyncMoc {
            newClient = UserClient.createOrUpdateSelfUserClient(newClientPayload, context: self.uiMOC)
            XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        }

        // then
        XCTAssertNotNil(newClient)
        XCTAssertNotNil(newClient.user)
        XCTAssertEqual(newClient.user, ZMUser.selfUser(in: uiMOC))
        XCTAssertNotNil(newClient.sessionIdentifier)
        XCTAssertEqual(newClient.mlsPublicKeys.ed25519, "some key")
        XCTAssertEqual(newClient.isConsumableNotificationsCapable, false)
    }

    func test_createOrUpdateSelfUserClient_WithAsyncStreamCapableTrue() {
        // given
        _ = createSelfClient()
        let newClientPayload: [String: AnyObject] = [
            "id": UUID().transportString() as AnyObject,
            "type": "permanent" as AnyObject,
            "time": Date().transportString() as AnyObject,
            "capabilities": ["consumable-notifications"] as AnyObject
        ]

        // when
        var newClient: UserClient!
        performPretendingUiMocIsSyncMoc {
            newClient = UserClient.createOrUpdateSelfUserClient(newClientPayload, context: self.uiMOC)
            XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        }

        // then
        XCTAssertNotNil(newClient)
        XCTAssertTrue(newClient.isConsumableNotificationsCapable)
    }

    func testThatItSetsTheUserWhenInsertingANewSelfUserClient_NoExistingSelfClient() {
        // given
        let newClientPayload: [String: AnyObject] = [
            "id": UUID().transportString() as AnyObject,
            "type": "permanent" as AnyObject,
            "time": Date().transportString() as AnyObject
        ]
        // when
        var newClient: UserClient!
        performPretendingUiMocIsSyncMoc {
            newClient = UserClient.createOrUpdateSelfUserClient(newClientPayload, context: self.uiMOC)
            XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        }

        // then
        XCTAssertNotNil(newClient)
        XCTAssertNotNil(newClient.user)
        XCTAssertEqual(newClient.user, ZMUser.selfUser(in: uiMOC))
        XCTAssertNil(newClient.sessionIdentifier)
    }

    func testThatItSetsNeedsSessionMigration_WhenInsertingANewSelfUserClientAndDomainIsNil() {
        // given
        _ = createSelfClient()
        let newClientPayload: [String: AnyObject] = [
            "id": UUID().transportString() as AnyObject,
            "type": "permanent" as AnyObject,
            "time": Date().transportString() as AnyObject
        ]
        // when
        var newClient: UserClient!
        performPretendingUiMocIsSyncMoc {
            newClient = UserClient.createOrUpdateSelfUserClient(newClientPayload, context: self.uiMOC)
            XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        }

        // then
        XCTAssertTrue(newClient.needsSessionMigration)
    }

    func testThatItSetsNeedsSessionMigration_WhenInsertingANewSelfUserClientAndDomainIsSet() {
        // given
        _ = createSelfClient()
        ZMUser.selfUser(in: uiMOC).domain = "example.com"

        let newClientPayload: [String: AnyObject] = [
            "id": UUID().transportString() as AnyObject,
            "type": "permanent" as AnyObject,
            "time": Date().transportString() as AnyObject
        ]
        // when
        var newClient: UserClient!
        performPretendingUiMocIsSyncMoc {
            newClient = UserClient.createOrUpdateSelfUserClient(newClientPayload, context: self.uiMOC)
            XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        }

        // then
        XCTAssertFalse(newClient.needsSessionMigration)
    }

    func testThatItCreatesUserClientIfNeeded() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            // WHEN
            let client = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: otherUser, createIfNeeded: true)

            // THEN
            XCTAssertNotNil(client)
            XCTAssertEqual(client?.remoteIdentifier, "badf00d")
            XCTAssertEqual(client?.user, otherUser)
        }
    }

    func testThatItSetsNeedsToMigrateSession_WhenCreatingUserClientAndDomainIsNil() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            // WHEN
            let client = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: otherUser, createIfNeeded: true)

            // THEN
            XCTAssertEqual(client?.needsSessionMigration, true)
        }
    }

    func testThatItSetsNeedsToMigrateSession_WhenCreatingUserClientAndDomainIsSet() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            otherUser.domain = "example.com"
            // WHEN
            let client = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: otherUser, createIfNeeded: true)

            // THEN
            XCTAssertEqual(client?.needsSessionMigration, false)
        }
    }

    func testThatItFetchesUserClientWithoutSave() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            // WHEN
            let client1 = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: otherUser, createIfNeeded: true)
            let client2 = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: otherUser, createIfNeeded: true)

            // THEN
            XCTAssertNotNil(client1)
            XCTAssertNotNil(client2)

            XCTAssertEqual(client1, client2)
        }
    }

    func testThatItFetchesUserClient_OtherMOC() {
        var clientSync: UserClient?
        let userUI = ZMUser.insertNewObject(in: uiMOC)
        userUI.remoteIdentifier = UUID.create()

        uiMOC.saveOrRollback()

        syncMOC.performGroupedAndWait {
            // GIVEN
            let userSync = try! self.syncMOC.existingObject(with: userUI.objectID) as! ZMUser
            // WHEN
            clientSync = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: userSync, createIfNeeded: true)
            clientSync?.label = "test"
            // THEN
            XCTAssertNotNil(clientSync)
            self.syncMOC.saveOrRollback()
        }

        // WHEN
        let clientUI: UserClient? = UserClient.fetchUserClient(
            withRemoteId: "badf00d",
            forUser: userUI,
            createIfNeeded: false
        )

        // THEN
        XCTAssertNotNil(clientUI)
        XCTAssertEqual(clientUI?.remoteIdentifier, "badf00d")
        XCTAssertEqual(clientUI?.label, "test")
    }

    func testThatItFetchesUserClientWithSave() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()
            // WHEN
            let client1 = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: otherUser, createIfNeeded: true)

            // AND THEN
            self.syncMOC.saveOrRollback()

            // WHEN
            let client2 = UserClient.fetchUserClient(withRemoteId: "badf00d", forUser: otherUser, createIfNeeded: true)

            // THEN
            XCTAssertNotNil(client1)
            XCTAssertNotNil(client2)

            XCTAssertEqual(client1, client2)
        }
    }
}

// MARK: - Update from payload

extension UserClientTests {

    func testThatItUpdatesDeviceClassFromPayload() {
        // given
        let allCases: [DeviceClass] = [.desktop, .phone, .tablet, .legalHold]
        let client = UserClient.insertNewObject(in: uiMOC)
        client.user = createUser(in: uiMOC)

        for deviceClass in allCases {
            // when
            client.update(with: ["class": deviceClass.rawValue])

            // then
            XCTAssertEqual(client.deviceClass, deviceClass)
        }
    }

    func testThatItSelfClientsAreNotUpdatedFromPayload() {
        // given
        let deviceClass = DeviceClass.desktop
        let selfClient = createSelfClient()

        // when
        selfClient.update(with: ["class": deviceClass.rawValue])

        // then
        XCTAssertNotEqual(selfClient.deviceClass, deviceClass)
    }

    func testThatItResetsNeedsToBeUpdatedFromBackend() {
        // given
        let client = UserClient.insertNewObject(in: uiMOC)
        client.user = createUser(in: uiMOC)
        client.needsToBeUpdatedFromBackend = true

        // when
        client.update(with: [:])

        // then
        XCTAssertFalse(client.needsToBeUpdatedFromBackend)
    }

}

// MARK: - Session Identifier

extension UserClientTests {

    func testThatItReturnsCorrectSessionIdentifier_WhenSessionNeedsMigration() {
        // given
        let user = createUser(in: uiMOC)

        let client = UserClient.insertNewObject(in: uiMOC)
        let clientID = UUID().uuidString
        client.remoteIdentifier = clientID
        client.user = user
        client.needsSessionMigration = true

        let userID = client.user!.remoteIdentifier.uuidString
        let expectedSessionIdentifier = ProteusSessionID(
            userID: userID,
            clientID: clientID
        )

        // when
        let sessionIdentifier = client.proteusSessionID

        // then
        XCTAssertEqual(sessionIdentifier, expectedSessionIdentifier)
    }

    func testThatItReturnsCorrectSessionIdentifier_WhenSessionDoesNotNeedMigration() {
        // given
        let domain = UUID().uuidString
        let user = createUser(in: uiMOC)
        user.domain = domain

        let client = UserClient.insertNewObject(in: uiMOC)
        let clientID = UUID().uuidString
        client.remoteIdentifier = clientID
        client.user = user
        client.needsSessionMigration = false

        let userID = client.user!.remoteIdentifier.uuidString
        let expectedSessionIdentifier = ProteusSessionID(
            domain: domain,
            userID: userID,
            clientID: clientID
        )

        // when
        let sessionIdentifier = client.proteusSessionID

        // then
        XCTAssertEqual(sessionIdentifier, expectedSessionIdentifier)
    }

}

// MARK: - MLS Public Keys

extension UserClientTests {

    func test_SettingNewMLSPublicKeys_MarksClientAsNeedingToUploadMLSPublicKeys() {
        // Given
        let client = UserClient.insertNewObject(in: uiMOC)
        XCTAssertEqual(client.modifiedKeys, nil)

        // When
        client.mlsPublicKeys = UserClient.MLSPublicKeys(ed25519: "foo")
        uiMOC.saveOrRollback()

        // Then
        XCTAssertEqual(client.modifiedKeys, Set([UserClient.needsToUploadMLSPublicKeysKey]))
    }

    func test_SettingSameMLSPublicKeys_DoesNot_MarkClientAsNeedingToUploadMLSPublicKeys() {
        // Given
        let client = UserClient.insertNewObject(in: uiMOC)
        client.mlsPublicKeys = UserClient.MLSPublicKeys(ed25519: "foo")
        uiMOC.saveOrRollback()

        client.resetLocallyModifiedKeys(Set([UserClient.needsToUploadMLSPublicKeysKey]))
        XCTAssertNil(client.modifiedKeys)

        // When
        client.mlsPublicKeys = UserClient.MLSPublicKeys(ed25519: "foo")
        uiMOC.saveOrRollback()

        // Then
        XCTAssertNil(client.modifiedKeys)
    }

}
