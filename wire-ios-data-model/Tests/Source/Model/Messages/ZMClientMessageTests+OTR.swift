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

import XCTest

@testable import WireDataModel
@testable import WireDataModelSupport

// swiftlint:disable todo_requires_jira_link
// TODO: this class is the same tests as ClientMessageTests_OTR_legacy but with proteusViaCoreCrypto true
// swiftlint:enable todo_requires_jira_link
// + mockProteusService setup
// as a cleanup we should remove the duplication and refactor this - WPB-5980
final class ClientMessageTests_OTR: BaseZMClientMessageTests {

    var mockProteusService: MockProteusServiceInterface!

    override func setUp() {
        super.setUp()
        DeveloperFlag.proteusViaCoreCrypto.enable(true, storage: .temporary())
        mockProteusService = MockProteusServiceInterface()

        // Mock
        setupMockProteusService()
    }

    private func setupMockProteusService() {
        self.mockProteusService.establishSessionIdFromPrekey_MockMethod = { _, _ in
            // No op
        }

        self.mockProteusService.remoteFingerprintForSession_MockMethod = { sessionID in
            return sessionID.rawValue + "remote_fingerprint"
        }

        self.mockProteusService.encryptDataForSession_MockMethod = { plaintext, _ in
            return plaintext
        }

        syncMOC.performGroupedBlockAndWait {
            self.syncMOC.proteusService = self.mockProteusService
        }
    }

    override func tearDown() {
        mockProteusService = nil

        DeveloperFlag.storage = UserDefaults.standard
        BackendInfo.domain = nil
        super.tearDown()
    }

    // MARK: - Payload creation

    func testThatCreatesEncryptedDataAndAddsItToGenericMessageAsBlob() async throws {
        let (textMessage, notSelfClients, firstClient, secondClient, conversation) = await self.syncMOC.perform {
            // Given
            let otherUser = ZMUser.insertNewObject(in: self.syncMOC)
            otherUser.remoteIdentifier = UUID.create()

            let firstClient = self.createClient(for: otherUser, createSessionWithSelfUser: true, onMOC: self.syncMOC)
            let secondClient = self.createClient(for: otherUser, createSessionWithSelfUser: true, onMOC: self.syncMOC)
            let selfClients = ZMUser.selfUser(in: self.syncMOC).clients
            let selfClient = ZMUser.selfUser(in: self.syncMOC).selfClient()
            let notSelfClients = selfClients.filter { $0 != selfClient }

            let nonce = UUID.create()
            let textMessage = GenericMessage(content: Text(content: self.textMessageRequiringExternalMessage(withNumberOfClients: 2)), nonce: nonce)

            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.remoteIdentifier = UUID.create()
            conversation.addParticipantAndUpdateConversationState(user: otherUser, role: nil)
            XCTAssertTrue(self.syncMOC.saveOrRollback())

            return (textMessage, notSelfClients, firstClient, secondClient, conversation)
        }

        // When
        let dataAndStrategy = await textMessage.encryptForTransport(for: conversation, in: syncMOC)
        let unwrappedDataAndStrategy = try XCTUnwrap(dataAndStrategy)

        // Then
        let createdMessage = Proteus_NewOtrMessage.with {
            try? $0.merge(serializedData: unwrappedDataAndStrategy.data)
        }

        XCTAssertEqual(createdMessage.hasBlob, true)
        await syncMOC.perform {
            let clientIds = createdMessage.recipients.flatMap { userEntry -> [Proteus_ClientId] in
                return (userEntry.clients).map { clientEntry -> Proteus_ClientId in
                    return clientEntry.client
                }
            }
            let clientSet = Set(clientIds)
            XCTAssertEqual(clientSet.count, 2 + notSelfClients.count)
            XCTAssertTrue(clientSet.contains(firstClient.clientId))
            XCTAssertTrue(clientSet.contains(secondClient.clientId))
            notSelfClients.forEach {
                XCTAssertTrue(clientSet.contains($0.clientId))
            }

            XCTAssertEqual(createdMessage.reportMissing.count, createdMessage.recipients.count)
        }
    }

    func testThatCorruptedClientsReceiveBogusPayload() async throws {
        let message = try await self.syncMOC.perform {
            // Given
            let message = try self.syncConversation.appendText(content: self.name, fetchLinkPreview: true, nonce: UUID.create()) as? ZMClientMessage
            self.syncUser3Client1.failedToEstablishSession = true
            return message
        }

        // When
        let unWrappedMessage = try XCTUnwrap(message)
        let dataAndStrategy = await unWrappedMessage.encryptForTransport()
        let unwrappedDataAndStrategy = try XCTUnwrap(dataAndStrategy)

        // Then
        let createdMessage = Proteus_NewOtrMessage.with {
            try? $0.merge(serializedData: unwrappedDataAndStrategy.data)
        }
        await syncMOC.perform {
            guard let userEntry = createdMessage.recipients.first(where: { self.syncUser3.userId == $0.user }) else { return XCTFail() }

            XCTAssertEqual(userEntry.clients.count, 1)
            XCTAssertEqual(userEntry.clients.first?.text, ZMFailedToCreateEncryptedMessagePayloadString.data(using: .utf8))
            XCTAssertFalse(self.syncUser3Client1.failedToEstablishSession)
        }
    }

    func testThatCorruptedClientsReceiveBogusPayloadWhenSentAsExternal() async throws {
        // Given
        let message = try await self.syncMOC.perform {
            let messageRequiringExternal = try XCTUnwrap(self.textMessageRequiringExternalMessage(withNumberOfClients: 6))
            let message = try self.syncConversation.appendText(content: messageRequiringExternal) as? ZMClientMessage
            self.syncUser3Client1.failedToEstablishSession = true
            return message
        }

        // When
        guard let dataAndStrategy = await message?.encryptForTransport() else {
            XCTFail()
            return
        }

        // Then
        await syncMOC.perform {
            let createdMessage = Proteus_NewOtrMessage.with {
                try? $0.merge(serializedData: dataAndStrategy.data)
            }
            guard let userEntry = createdMessage.recipients.first(where: { self.syncUser3.userId == $0.user }) else { return XCTFail() }

            XCTAssertEqual(userEntry.clients.count, 1)
            XCTAssertEqual(userEntry.clients.first?.text, ZMFailedToCreateEncryptedMessagePayloadString.data(using: .utf8))
            XCTAssertFalse(self.syncUser3Client1.failedToEstablishSession)
        }
    }

    func testThatItCreatesPayloadDataForTextMessage() async throws {
        // Mock
        self.mockProteusService.encryptDataForSession_MockMethod = { plaintext, sessionID in
            let expectedRecipientClientIDs = self.expectedRecipients.values.flatMap(\.self)

            if sessionID.clientID.isOne(of: expectedRecipientClientIDs) {
                return plaintext
            } else {
                throw ProteusService.EncryptionError.failedToEncryptData
            }
        }

        let message = try await self.syncMOC.perform {
            // Given
            let message = try self.syncConversation.appendText(content: self.name, fetchLinkPreview: true, nonce: UUID.create()) as? ZMClientMessage

            return message
        }

        // When
        guard let payloadAndStrategy = await message?.encryptForTransport() else {
            XCTFail()
            return
        }

        // Then
        await self.syncMOC.perform {
            self.assertMessageMetadata(payloadAndStrategy.data)
            switch payloadAndStrategy.strategy {
            case .doNotIgnoreAnyMissingClient:
                break
            default:
                XCTFail()
            }
        }
    }

    func testThatItCreatesPayloadDataForEphemeralTextMessage_Group() async throws {
        let message = try await self.syncMOC.perform {
            // Given
            self.syncConversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)
            let message = try XCTUnwrap(
                try self.syncConversation.appendText(content: self.name, fetchLinkPreview: true, nonce: UUID.create()) as? ZMClientMessage
            )

            XCTAssertTrue(message.isEphemeral)
            return message
        }

        // Mock
        self.mockProteusService.encryptDataForSession_MockMethod = { plaintext, _ in
            return plaintext
        }

        // When
        guard let payloadAndStrategy = await message.encryptForTransport() else { return XCTFail() }

        // Then
        switch payloadAndStrategy.strategy {
        case .ignoreAllMissingClientsNotFromUsers, .ignoreAllMissingClients:
            XCTFail()
        default:
            break
        }
    }

    func testThatItCreatesPayloadDataForDeletionOfEphemeralTextMessage_Group() async throws {
        let syncMessage: ZMClientMessage? = try await self.syncMOC.perform {
            // Given
            self.syncConversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)
            let syncMessage = try self.syncConversation.appendText(content: self.name, fetchLinkPreview: true, nonce: UUID.create()) as? ZMClientMessage
            syncMessage?.sender = self.syncUser1
            XCTAssertTrue(syncMessage?.isEphemeral == true)
            self.syncMOC.saveOrRollback()
            return syncMessage
        }

        guard let syncMessage else {
            XCTFail("missing syncMessage")
            return
        }

        await uiMOC.perform {
            let uiMessage = self.uiMOC.object(with: syncMessage.objectID) as! ZMMessage
            uiMessage.startDestructionIfNeeded()
            XCTAssertNotNil(uiMessage.destructionDate)
            self.uiMOC.zm_teardownMessageDeletionTimer()
            self.uiMOC.saveOrRollback()
        }

        let sut = await self.syncMOC.perform {
            self.syncMOC.refresh(syncMessage, mergeChanges: true)
            XCTAssertNotNil(syncMessage.destructionDate)

            return syncMessage.deleteForEveryone()
        }

        // When
        guard let payloadAndStrategy = await sut?.encryptForTransport() else { return XCTFail() }

        // Then
        await syncMOC.perform {
            switch payloadAndStrategy.strategy {
            case .ignoreAllMissingClientsNotFromUsers(users: let users):
                XCTAssertEqual(users, [self.syncSelfUser, self.syncUser1])
            default:
                XCTFail()
            }
        }
    }

    func testThatItCreatesPayloadForDeletionOfEphemeralTextMessage_Group_SenderWasDeleted() async throws {
        // This can happen due to a race condition where we receive a delete for an ephemeral after deleting the same message locally, but before creating the payload
        let syncMessage = try await self.syncMOC.perform {
            // Given
            self.syncConversation.setMessageDestructionTimeoutValue(.tenSeconds, for: .selfUser)
            let syncMessage = try self.syncConversation.appendText(content: self.name, fetchLinkPreview: true, nonce: UUID.create()) as? ZMClientMessage
            syncMessage?.sender = self.syncUser1
            XCTAssertTrue(syncMessage?.isEphemeral == true)
            self.syncMOC.saveOrRollback()
            return syncMessage
        }

        guard let syncMessage else {
            XCTFail("syncMessage missing")
            return
        }

        await uiMOC.perform {
            let uiMessage = self.uiMOC.object(with: syncMessage.objectID) as! ZMMessage
            uiMessage.startDestructionIfNeeded()
            XCTAssertNotNil(uiMessage.destructionDate)
            self.uiMOC.zm_teardownMessageDeletionTimer()
            self.uiMOC.saveOrRollback()
        }

        let sut = await self.syncMOC.perform {
            self.syncMOC.refresh(syncMessage, mergeChanges: true)
            XCTAssertNotNil(syncMessage.destructionDate)

            let sut = syncMessage.deleteForEveryone()

            // When
            syncMessage.sender = nil
            return sut
        }
        var payload: (data: Data, strategy: MissingClientsStrategy)?
        self.disableZMLogError(true)
        payload = await sut?.encryptForTransport()
        self.disableZMLogError(false)

        // Then
        await syncMOC.perform {
            guard let payloadAndStrategy = payload else { return XCTFail() }
            switch payloadAndStrategy.strategy {
            case .ignoreAllMissingClientsNotFromUsers(users: let users):
                XCTAssertEqual(users, [self.syncSelfUser])
            default:
                XCTFail()
            }
        }
    }

    func testThatItCreatesPayloadForZMLastReadMessages() async throws {
        // Given
        BackendInfo.storage = .temporary()
        BackendInfo.domain = "example.domain.com"

        let message = try await self.syncMOC.perform {
            self.syncConversation.lastReadServerTimeStamp = Date()
            self.syncConversation.remoteIdentifier = UUID()
            let message = try ZMConversation.updateSelfConversation(withLastReadOf: self.syncConversation)

            self.expectedRecipients = [self.syncSelfUser.remoteIdentifier!.transportString(): [self.syncSelfClient2.remoteIdentifier!]]
            return message
        }

        // When
        guard let payloadAndStrategy = await message.encryptForTransport() else { return XCTFail() }

        // Then
        await syncMOC.perform {
            self.assertMessageMetadata(payloadAndStrategy.data)
            switch payloadAndStrategy.strategy {
            case .doNotIgnoreAnyMissingClient:
                break
            default:
                XCTFail()
            }

        }
    }

    func testThatItCreatesPayloadForZMClearedMessages() async throws {
        let message = try await self.syncMOC.perform {
            // Given
            self.syncConversation.clearedTimeStamp = Date()
            self.syncConversation.remoteIdentifier = UUID()
            let message = try ZMConversation.updateSelfConversation(withClearedOf: self.syncConversation)

            self.expectedRecipients = [self.syncSelfUser.remoteIdentifier!.transportString(): [self.syncSelfClient2.remoteIdentifier!]]
            return message
        }

        // When
        guard let payloadAndStrategy = await message.encryptForTransport() else { return XCTFail() }

        await syncMOC.perform {
            // Then
            self.assertMessageMetadata(payloadAndStrategy.data)
            switch payloadAndStrategy.strategy {
            case .doNotIgnoreAnyMissingClient:
                break
            default:
                XCTFail()
            }
        }
    }

    // MARK: - Delivery

    func testThatItCreatesPayloadDataForConfirmationMessage() async throws {
        let confirmationMessage = try await self.syncMOC.perform {
            // Given
            let senderID = self.syncUser1.clients.first!.remoteIdentifier
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .oneOnOne
            conversation.remoteIdentifier = UUID.create()

            let connection = ZMConnection.insertNewObject(in: self.syncMOC)
            connection.to = self.syncUser1
            connection.status = .accepted
            self.syncUser1.oneOnOneConversation = conversation
            conversation.addParticipantAndUpdateConversationState(user: self.syncUser1, role: nil)

            self.syncMOC.saveOrRollback()

            let textMessage = try conversation.appendText(content: self.stringLargeEnoughToRequireExternal, fetchLinkPreview: true, nonce: UUID.create()) as? ZMClientMessage

            textMessage?.sender = self.syncUser1
            textMessage?.senderClientID = senderID

            let textMessageNonce = try XCTUnwrap(textMessage?.nonce)

            let genericMessage = GenericMessage(content: Confirmation(messageId: textMessageNonce, type: .delivered))
            return try conversation.appendClientMessage(with: genericMessage, expires: false, hidden: true)
        }

        // When
        let payloadAndStrategy = await confirmationMessage.encryptForTransport()
        let unWrappedPayloadAndStrategy = try XCTUnwrap(payloadAndStrategy)

        await syncMOC.perform {
            // Then
            switch unWrappedPayloadAndStrategy.strategy {
            case .ignoreAllMissingClientsNotFromUsers(let users):
                XCTAssertEqual(users, [self.syncUser1])
            default:
                XCTFail()
            }
            let messageMetadata = Proteus_NewOtrMessage.with {
                try? $0.merge(serializedData: unWrappedPayloadAndStrategy.data)
            }

            let payloadClients = messageMetadata.recipients.compactMap { user -> [String] in
                return user.clients.map({ String(format: "%llx", $0.client.client) })
            }.flatMap { $0 }
            XCTAssertEqual(payloadClients.sorted(), self.syncUser1.clients.map { $0.remoteIdentifier! }.sorted())
        }
    }

    func testThatItCreatesPayloadForConfimationMessageWhenOriginalHasSender() async throws {
        let confirmationMessage = try await syncMOC.perform {
            // Given
            let senderID = self.syncUser1.clients.first!.remoteIdentifier
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .oneOnOne
            conversation.remoteIdentifier = UUID.create()

            let connection = ZMConnection.insertNewObject(in: self.syncMOC)
            connection.to = self.syncUser1
            connection.status = .accepted
            self.syncUser1.oneOnOneConversation = conversation
            conversation.addParticipantAndUpdateConversationState(user: self.syncUser1, role: nil)

            self.syncMOC.saveOrRollback()

            let textMessage = try conversation.appendText(content: self.stringLargeEnoughToRequireExternal, fetchLinkPreview: true, nonce: UUID.create()) as? ZMClientMessage

            textMessage?.sender = self.syncUser1
            textMessage?.senderClientID = senderID

            let textMessageNonce = try XCTUnwrap(textMessage?.nonce)

            let confirmation = GenericMessage(content: Confirmation(messageId: textMessageNonce, type: .delivered))
            return try conversation.appendClientMessage(with: confirmation, expires: false, hidden: true)
        }

        // When
        let result = await confirmationMessage.encryptForTransport()
        await syncMOC.perform {
            XCTAssertNotNil(result)
        }
    }

    func testThatItCreatesPayloadForConfimationMessageWhenOriginalHasNoSenderButInferSenderWithConnection() async throws {
        let confirmationMessage = try await syncMOC.perform {
            // Given
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .oneOnOne
            conversation.remoteIdentifier = UUID.create()

            let connection = ZMConnection.insertNewObject(in: self.syncMOC)
            connection.to = self.syncUser1
            connection.status = .accepted
            self.syncUser1.oneOnOneConversation = conversation

            let genericMessage = GenericMessage(content: Text(content: "yo"), nonce: UUID.create())
            let clientmessage = ZMClientMessage(nonce: UUID(), managedObjectContext: self.syncMOC)
            try clientmessage.setUnderlyingMessage(genericMessage)
            clientmessage.visibleInConversation = conversation

            self.syncMOC.saveOrRollback()

            let nonce = try XCTUnwrap(clientmessage.nonce)
            let confirmation = GenericMessage(content: Confirmation(messageId: nonce, type: .delivered))
            return try conversation.appendClientMessage(with: confirmation, expires: false, hidden: true)
        }

        // When
        let result = await confirmationMessage.encryptForTransport()
        await syncMOC.perform {
            XCTAssertNotNil(result)
        }
    }

    func testThatItCreatesPayloadForConfimationMessageWhenOriginalHasNoSenderAndConnectionButInferSenderOtherActiveParticipants() async throws {
        let confirmationMessage = try await syncMOC.perform {
            // Given
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .oneOnOne
            conversation.remoteIdentifier = UUID.create()
            conversation.addParticipantAndUpdateConversationState(user: self.syncUser1, role: nil)

            let genericMessage = GenericMessage(content: Text(content: "yo"), nonce: UUID.create())
            let clientMessage = ZMClientMessage(nonce: UUID(), managedObjectContext: self.syncMOC)
            try clientMessage.setUnderlyingMessage(genericMessage)
            clientMessage.visibleInConversation = conversation

            self.syncMOC.saveOrRollback()

            let confirmation = GenericMessage(content: Confirmation(messageId: clientMessage.nonce!, type: .delivered))
            return try conversation.appendClientMessage(with: confirmation, expires: false, hidden: true)
        }

        // When
        let result = await confirmationMessage.encryptForTransport()
        await syncMOC.perform {
            XCTAssertNotNil(result)
        }
    }

    // MARK: - Session identifier

    func testThatItUsesTheProperSessionIdentifier() {
        // GIVEN
        let user = ZMUser.insertNewObject(in: self.uiMOC)
        user.remoteIdentifier = UUID.create()
        let client = UserClient.insertNewObject(in: self.uiMOC)
        client.user = user
        client.remoteIdentifier = UUID.create().transportString()

        // WHEN
        let identifier = client.proteusSessionID

        // THEN
        XCTAssertEqual(identifier, ProteusSessionID(userID: user.remoteIdentifier.uuidString, clientID: client.remoteIdentifier!))
    }

    // MARK: - Helper

    /// Returns a string large enough to have to be encoded in an external message
    fileprivate var stringLargeEnoughToRequireExternal: String {
        var text = "Hello"
        while text.data(using: String.Encoding.utf8)!.count < Int(ZMClientMessage.byteSizeExternalThreshold) {
            text.append(text)
        }
        return text
    }

    /// Asserts that the message metadata is as expected
    fileprivate func assertMessageMetadata(_ payload: Data!, file: StaticString = #file, line: UInt = #line) {
        let messageMetadata = Proteus_NewOtrMessage.with {
            try? $0.merge(serializedData: payload)
        }

        let client = self.uiMOC.performAndWait({ self.selfClient1.clientId.client })
        XCTAssertEqual(messageMetadata.sender.client, client, file: file, line: line)
        assertRecipients(messageMetadata.recipients, file: file, line: line)
    }

    /// Returns a string that is big enough to require external message payload
    fileprivate func textMessageRequiringExternalMessage(_ numberOfClients: UInt) -> String {
        var string = "Exponential growth!"
        while string.data(using: String.Encoding.utf8)!.count < Int(ZMClientMessage.byteSizeExternalThreshold / numberOfClients) {
            string += string
        }
        return string
    }

}

extension DatabaseBaseTest {

    func createSelfUser(in moc: NSManagedObjectContext) -> (ZMUser, ZMConversation) {
        let selfUser = ZMUser.selfUser(in: moc)
        selfUser.remoteIdentifier = UUID()
        let conversation = ZMConversation.fetchOrCreate(with: selfUser.remoteIdentifier,
                                                        domain: nil,
                                                        in: moc)
        moc.saveOrRollback()
        return (selfUser, conversation)
    }

    func createSelfClient(on moc: NSManagedObjectContext) -> UserClient {
        let selfUser = ZMUser.selfUser(in: moc)

        let selfClient = UserClient.insertNewObject(in: moc)
        selfClient.remoteIdentifier = .randomRemoteIdentifier()
        selfClient.user = selfUser

        moc.setPersistentStoreMetadata(selfClient.remoteIdentifier, key: ZMPersistedClientIdKey)

        let payload = ["id": selfClient.remoteIdentifier!,
                       "type": "permanent",
                       "time": Date().transportString()] as [String: AnyObject]
        _ = UserClient.createOrUpdateSelfUserClient(payload, context: moc)

        moc.saveOrRollback()
        return selfClient
    }
}
