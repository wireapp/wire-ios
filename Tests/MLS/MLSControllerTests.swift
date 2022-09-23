//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import XCTest
@testable import WireDataModel

class MLSControllerTests: ZMConversationTestsBase, MLSControllerDelegate {

    var sut: MLSController!
    var mockCoreCrypto: MockCoreCrypto!
    var mockActionsProvider: MockMLSActionsProvider!
    var mockConversationEventProcessor: MockConversationEventProcessor!
    var mockStaleMLSKeyDetector: MockStaleMLSKeyDetector!
    var userDefaultsTestSuite: UserDefaults!

    let groupID = MLSGroupID([1, 2, 3])

    override func setUp() {
        super.setUp()
        mockCoreCrypto = MockCoreCrypto()
        mockActionsProvider = MockMLSActionsProvider()
        mockConversationEventProcessor = MockConversationEventProcessor()
        mockStaleMLSKeyDetector = MockStaleMLSKeyDetector()
        userDefaultsTestSuite = UserDefaults(suiteName: "com.wire.mls-test-suite")!

        sut = MLSController(
            context: uiMOC,
            coreCrypto: mockCoreCrypto,
            conversationEventProcessor: mockConversationEventProcessor,
            staleKeyMaterialDetector: mockStaleMLSKeyDetector,
            actionsProvider: mockActionsProvider,
            userDefaults: userDefaultsTestSuite
        )

        sut.delegate = self
    }

    override func tearDown() {
        sut = nil
        mockCoreCrypto = nil
        mockActionsProvider = nil
        mockStaleMLSKeyDetector = nil
        super.tearDown()
    }

    // MARK: - MLSControllerDelegate

    var pendingProposalCommitExpectations = [MLSGroupID: XCTestExpectation]()
    var keyMaterialUpdatedExpectation: XCTestExpectation?

    // Since SUT may schedule timers to commit pending proposals, we create expectations
    // and fulfill them when SUT informs us the commit was made.

    func mlsControllerDidCommitPendingProposal(for: MLSGroupID) {
        pendingProposalCommitExpectations[groupID]?.fulfill()
    }

    func mlsControllerDidUpdateKeyMaterialForAllGroups() {
        keyMaterialUpdatedExpectation?.fulfill()
    }

    // MARK: - Public keys

    func test_BackendPublicKeysAreFetched_WhenInitializing() throws {
        // Mock
        let keys = BackendMLSPublicKeys(
            removal: .init(ed25519: Data([1, 2, 3]))
        )

        // expectation
        let expectation = XCTestExpectation(description: "Fetch backend public keys")

        mockActionsProvider.fetchBackendPublicKeysMocks.append({
            expectation.fulfill()
            return keys
        })

        // When
        let sut = MLSController(
            context: uiMOC,
            coreCrypto: mockCoreCrypto,
            conversationEventProcessor: mockConversationEventProcessor,
            staleKeyMaterialDetector: mockStaleMLSKeyDetector,
            actionsProvider: mockActionsProvider
        )

        // Then
        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(sut.backendPublicKeys, keys)
    }

    // MARK: - Message Encryption

    typealias EncryptionError = MLSController.MLSMessageEncryptionError

    func test_Encrypt_IsSuccessful() {
        do {
            // Given
            let groupID = MLSGroupID([1, 1, 1])
            let unencryptedMessage: Bytes = [2, 2, 2]
            let encryptedMessage: Bytes = [3, 3, 3]

            // Mock
            var mockEncryptMessageCount = 0
            mockCoreCrypto.mockEncryptMessage = {
                mockEncryptMessageCount += 1
                XCTAssertEqual($0, groupID.bytes)
                XCTAssertEqual($1, unencryptedMessage)
                return encryptedMessage
            }

            // When
            let result = try sut.encrypt(message: unencryptedMessage, for: groupID)

            // Then
            XCTAssertEqual(mockEncryptMessageCount, 1)
            XCTAssertEqual(result, encryptedMessage)

        } catch {
            XCTFail("Unexpected error: \(String(describing: error))")
        }
    }

    func test_Encrypt_Fails() {
        // Given
        let groupID = MLSGroupID([1, 1, 1])
        let unencryptedMessage: Bytes = [2, 2, 2]

        // Mock
        mockCoreCrypto.mockEncryptMessage = { (_, _) in
            throw CryptoError.InvalidByteArrayError(message: "bad bytes!")
        }

        // When / Then
        assertItThrows(error: EncryptionError.failedToEncryptMessage) {
            _ = try sut.encrypt(message: unencryptedMessage, for: groupID)
        }
    }

    // MARK: - Message Decryption

    typealias DecryptionError = MLSController.MLSMessageDecryptionError

    func test_Decrypt_ThrowsFailedToConvertMessageToBytes() {
        syncMOC.performAndWait {
            // Given
            let invalidBase64String = "%"

            // When / Then
            assertItThrows(error: DecryptionError.failedToConvertMessageToBytes) {
                try _ = sut.decrypt(message: invalidBase64String, for: groupID)
            }
        }
    }

    func test_Decrypt_ThrowsFailedToDecryptMessage() {
        syncMOC.performAndWait {
            // Given
            let message = Data([1, 2, 3]).base64EncodedString()
            self.mockCoreCrypto.mockDecryptMessage = { _, _ in
                throw CryptoError.ConversationNotFound(message: "conversation not found")
            }

            // When / Then
            assertItThrows(error: DecryptionError.failedToDecryptMessage) {
                try _ = sut.decrypt(message: message, for: groupID)
            }
        }
    }

    func test_Decrypt_ReturnsNil_WhenCoreCryptoReturnsNil() {
        syncMOC.performAndWait {
            // Given
            let messageBytes: Bytes = [1, 2, 3]
            self.mockCoreCrypto.mockDecryptMessage = { _, _ in
                DecryptedMessage(
                    message: nil,
                    proposals: [],
                    isActive: false,
                    commitDelay: nil
                )
            }

            // When
            var result: MLSDecryptResult?
            do {
                result = try sut.decrypt(message: messageBytes.data.base64EncodedString(), for: groupID)
            } catch {
                XCTFail("Unexpected error: \(String(describing: error))")
            }

            // Then
            XCTAssertNil(result)
        }
    }

    func test_Decrypt_IsSuccessful() {
        syncMOC.performAndWait {
            // Given
            let messageBytes: Bytes = [1, 2, 3]

            var mockDecryptMessageCount = 0
            self.mockCoreCrypto.mockDecryptMessage = {
                mockDecryptMessageCount += 1

                XCTAssertEqual($0, self.groupID.bytes)
                XCTAssertEqual($1, messageBytes)

                return DecryptedMessage(
                    message: messageBytes,
                    proposals: [],
                    isActive: false,
                    commitDelay: nil
                )
            }

            // When
            var result: MLSDecryptResult?
            do {
                result = try sut.decrypt(message: messageBytes.data.base64EncodedString(), for: groupID)
            } catch {
                XCTFail("Unexpected error: \(String(describing: error))")
            }

            // Then
            XCTAssertEqual(mockDecryptMessageCount, 1)
            XCTAssertEqual(result, MLSDecryptResult.message(messageBytes.data))
        }
    }

    // MARK: - Create group

    func test_CreateGroup_IsSuccessful() throws {
        // Given
        let groupID = MLSGroupID(Data([1, 2, 3]))
        let removalKey = Data([1, 2, 3])

        sut.backendPublicKeys = BackendMLSPublicKeys(
            removal: .init(ed25519: removalKey)
        )

        var mockCreateConversationCount = 0
        mockCoreCrypto.mockCreateConversation = {
            mockCreateConversationCount += 1

            XCTAssertEqual($0, groupID.bytes)
            XCTAssertEqual($1, ConversationConfiguration(
                ciphersuite: .mls128Dhkemx25519Aes128gcmSha256Ed25519,
                externalSenders: [removalKey.bytes]
            ))
        }

        // When
        XCTAssertNoThrow(try sut.createGroup(for: groupID))

        // Then
        XCTAssertEqual(mockCreateConversationCount, 1)
        XCTAssertEqual(mockStaleMLSKeyDetector.calls.keyingMaterialUpdated, [groupID])
    }

    func test_CreateGroup_ThrowsError() throws {
        // Given
        let groupID = MLSGroupID(Data([1, 2, 3]))

        var mockCreateConversationCount = 0
        mockCoreCrypto.mockCreateConversation = {
            mockCreateConversationCount += 1

            XCTAssertEqual($0, groupID.bytes)
            XCTAssertEqual($1, ConversationConfiguration(ciphersuite: .mls128Dhkemx25519Aes128gcmSha256Ed25519))

            throw CryptoError.MalformedIdentifier(message: "bad id")
        }

        // when / then
        assertItThrows(error: MLSController.MLSGroupCreationError.failedToCreateGroup) {
            try sut.createGroup(for: groupID)
        }

        // Then
        XCTAssertEqual(mockCreateConversationCount, 1)
    }

    // MARK: - Adding participants

    func test_AddingMembersToConversation_Successfully() async {
        // Given
        let domain = "example.com"
        let id = UUID.create()
        let mlsGroupID = MLSGroupID(Data([1, 2, 3]))
        let mlsUser: [MLSUser] = [MLSUser(id: id, domain: domain)]

        // Mock key package.
        var keyPackage: KeyPackage!

        mockActionsProvider.claimKeyPackagesMocks.append({ userID, _, _ in
            keyPackage = KeyPackage(
                client: "client",
                domain: domain,
                keyPackage: Data([1, 2, 3]).base64EncodedString(),
                keyPackageRef: "keyPackageRef",
                userID: userID
            )

            return [keyPackage]
        })

        // Mock return value for adding clients to conversation.
        var mockAddClientsToConversationCount = 0
        mockCoreCrypto.mockAddClientsToConversation = {
            mockAddClientsToConversationCount += 1

            XCTAssertEqual($0, mlsGroupID.bytes)
            XCTAssertEqual($1, [Invitee(from: keyPackage)])

            return MemberAddedMessages(
                commit: [0, 0, 0, 0],
                welcome: [1, 1, 1, 1],
                publicGroupState: []
            )
        }

        mockCoreCrypto.mockCommitAccepted = {
            XCTAssertEqual($0, mlsGroupID.bytes)
        }

        // Mock update event for member joins the conversation
        var updateEvent: ZMUpdateEvent!

        // Mock sending message.
        mockActionsProvider.sendMessageMocks.append({ message in
            XCTAssertEqual(message, Data([0, 0, 0, 0]))

            let mockPayload: NSDictionary = [
                "type": "conversation.member-join",
                "data": message
            ]

            updateEvent = ZMUpdateEvent(fromEventStreamPayload: mockPayload, uuid: nil)!

            return [updateEvent]
        })

        // Mock sending welcome message.
        mockActionsProvider.sendWelcomeMessageMocks.append({ message in
            XCTAssertEqual(message, Data([1, 1, 1, 1]))
        })

        do {
            // When
            try await sut.addMembersToConversation(with: mlsUser, for: mlsGroupID)

        } catch let error {
            XCTFail("Unexpected error: \(String(describing: error))")
        }

        let processConversationEventsCalls = self.mockConversationEventProcessor.calls.processConversationEvents
        XCTAssertEqual(processConversationEventsCalls.count, 1)
        XCTAssertEqual(processConversationEventsCalls[0], [updateEvent])
    }

    func test_AddingMembersToConversation_ThrowsNoParticipantsToAdd() async {
        // Given
        let mlsGroupID = MLSGroupID(Data([1, 2, 3]))
        let mlsUser = [MLSUser]()

        mockCoreCrypto.mockCommitAccepted = { _ in
            XCTFail("commit should not be accepted")
        }

        // when / then
        await assertItThrows(error: MLSController.MLSGroupCreationError.noParticipantsToAdd) {
            try await sut.addMembersToConversation(with: mlsUser, for: mlsGroupID)
        }
    }

    func test_AddingMembersToConversation_ThrowsFailedToClaimKeyPackages() async {
        // Given
        let domain = "example.com"
        let id = UUID.create()
        let mlsGroupID = MLSGroupID(Data([1, 2, 3]))
        let mlsUser: [MLSUser] = [MLSUser(id: id, domain: domain)]

        mockCoreCrypto.mockCommitAccepted = { _ in
            XCTFail("commit should not be accepted")
        }

        do {
            // When
            try await sut.addMembersToConversation(with: mlsUser, for: mlsGroupID)

        } catch let error {
            // Then
            switch error {
            case MLSController.MLSGroupCreationError.failedToClaimKeyPackages:
                break

            default:
                XCTFail("Unexpected error: \(String(describing: error))")
            }
        }
    }

    func test_AddingMembersToConversation_ThrowsFailedToSendCommit() async {
        // Given
        let domain = "example.com"
        let id = UUID.create()
        let mlsGroupID = MLSGroupID(Data([1, 2, 3]))
        let mlsUser: [MLSUser] = [MLSUser(id: id, domain: domain)]

        // Mock key package.
        var keyPackage: KeyPackage!

        mockActionsProvider.claimKeyPackagesMocks.append({ userID, _, _ in
            keyPackage = KeyPackage(
                client: "client",
                domain: domain,
                keyPackage: Data([1, 2, 3]).base64EncodedString(),
                keyPackageRef: "keyPackageRef",
                userID: userID
            )

            return [keyPackage]
        })

        // Mock return value for adding clients to conversation.
        mockCoreCrypto.mockAddClientsToConversation = { _, _ in
            MemberAddedMessages(
                commit: [0, 0, 0, 0],
                welcome: [1, 1, 1, 1],
                publicGroupState: []
            )
        }

        mockCoreCrypto.mockCommitAccepted = { _ in
            XCTFail("commit should not be accepted")
        }

        // when / then
        await assertItThrows(error: MLSController.MLSSendMessageError.failedToSendCommit) {
            try await sut.addMembersToConversation(with: mlsUser, for: mlsGroupID)
        }
    }

    func test_AddingMembersToConversation_ThrowsFailedToSendWelcomeMessage() async {
        // Given
        let domain = "example.com"
        let id = UUID.create()
        let mlsGroupID = MLSGroupID(Data([1, 2, 3]))
        let mlsUser: [MLSUser] = [MLSUser(id: id, domain: domain)]

        // Mock key package.
        var keyPackage: KeyPackage!

        mockActionsProvider.claimKeyPackagesMocks.append({ userID, _, _ in
            keyPackage = KeyPackage(
                client: "client",
                domain: domain,
                keyPackage: Data([1, 2, 3]).base64EncodedString(),
                keyPackageRef: "keyPackageRef",
                userID: userID
            )

            return [keyPackage]
        })

        // Mock return value for adding clients to conversation.
        mockCoreCrypto.mockAddClientsToConversation = { _, _ in
            MemberAddedMessages(
                commit: [0, 0, 0, 0],
                welcome: [1, 1, 1, 1],
                publicGroupState: []
            )
        }

        mockCoreCrypto.mockCommitAccepted = {
            XCTAssertEqual($0, mlsGroupID.bytes)
        }

        // Mock update event for member joins the conversation
        var updateEvent: ZMUpdateEvent!

        // Mock sending message.
        mockActionsProvider.sendMessageMocks.append({ message in
            XCTAssertEqual(message, Data([0, 0, 0, 0]))

            let mockPayload: NSDictionary = [
                "type": "conversation.member-join",
                "data": message
            ]

            updateEvent = ZMUpdateEvent(fromEventStreamPayload: mockPayload, uuid: nil)!

            return [updateEvent]
        })

        // When / Then
        await assertItThrows(error: MLSController.MLSGroupCreationError.failedToSendWelcomeMessage) {
            try await sut.addMembersToConversation(with: mlsUser, for: mlsGroupID)
        }

        let processConversationEventsCalls = self.mockConversationEventProcessor.calls.processConversationEvents
        XCTAssertEqual(processConversationEventsCalls.count, 1)
        XCTAssertEqual(processConversationEventsCalls[0], [updateEvent])
    }

    // MARK: - Remove participants

    func test_RemoveMembersFromConversation_IsSuccessful() async {
        // Given
        let domain = "example.com"
        let id = UUID.create().uuidString
        let clientID = UUID.create().uuidString
        let mlsGroupID = MLSGroupID(Data([1, 2, 3]))
        let mlsClientID = MLSClientID(userID: id, clientID: clientID, domain: domain)

        // Mock return value for removing clients to conversation.
        var mockRemoveClientsFromConversationCount = 0
        mockCoreCrypto.mockRemoveClientsFromConversation = {
            mockRemoveClientsFromConversationCount += 1

            XCTAssertEqual($0, mlsGroupID.bytes)
            let mlsClientIDBytes = mlsClientID.string.data(using: .utf8)!.bytes
            XCTAssertEqual($1, [mlsClientIDBytes])

            return CommitBundle(
                welcome: nil,
                commit: [0, 0, 0, 0],
                publicGroupState: []
            )
        }

        // Mock update event for member leaves from conversation
        var updateEvent: ZMUpdateEvent!

        // Mock sending message.
        mockActionsProvider.sendMessageMocks.append({ message in
            XCTAssertEqual(message, Data([0, 0, 0, 0]))

            let mockPayload: NSDictionary = [
                "type": "conversation.member-leave",
                "data": message
            ]

            updateEvent = ZMUpdateEvent(fromEventStreamPayload: mockPayload, uuid: nil)!

            return [updateEvent]
        })

        mockCoreCrypto.mockCommitAccepted = {
            XCTAssertEqual($0, mlsGroupID.bytes)
        }

        do {
            // When
            try await sut.removeMembersFromConversation(with: [mlsClientID], for: mlsGroupID)

        } catch let error {
            XCTFail("Unexpected error: \(String(describing: error))")
        }

        // Then
        let processConversationEventsCalls = self.mockConversationEventProcessor.calls.processConversationEvents
        XCTAssertEqual(processConversationEventsCalls.count, 1)
        XCTAssertEqual(processConversationEventsCalls[0], [updateEvent])

        XCTAssertEqual(mockRemoveClientsFromConversationCount, 1)
    }

    func test_RemovingMembersToConversation_ThrowsNoClientsToRemove() async {
        // Given
        let mlsGroupID = MLSGroupID(Data([1, 2, 3]))

        var mockCommitAcceptedCount = 0
        mockCoreCrypto.mockCommitAccepted = { _ in
            mockCommitAcceptedCount += 1
        }

        // When / Then
        await assertItThrows(error: MLSController.MLSRemoveParticipantsError.noClientsToRemove) {
            try await sut.removeMembersFromConversation(with: [], for: mlsGroupID)
        }

        XCTAssertEqual(mockCommitAcceptedCount, 0)
    }

    func test_RemovingMembersToConversation_FailsToSendCommit() async {
        // Given
        let domain = "example.com"
        let id = UUID.create().uuidString
        let clientID = UUID.create().uuidString
        let mlsGroupID = MLSGroupID(Data([1, 2, 3]))
        let mlsClientID = MLSClientID(userID: id, clientID: clientID, domain: domain)

        // Mock return value for removing clients to conversation.
        mockCoreCrypto.mockRemoveClientsFromConversation = { _, _ in
            CommitBundle(
                welcome: nil,
                commit: [0, 0, 0, 0],
                publicGroupState: []
            )
        }

        mockCoreCrypto.mockCommitAccepted = { _ in
            XCTFail("commit should not be accepted")
        }

        // When / Then
        await assertItThrows(error: MLSController.MLSSendMessageError.failedToSendCommit) {
            try await sut.removeMembersFromConversation(with: [mlsClientID], for: mlsGroupID)
        }
    }

    // MARK: - Pending proposals

    func test_SchedulePendingProposalCommit() throws {
        // Given
        let conversationID = UUID.create()
        let groupID = MLSGroupID([1, 2, 3])

        let conversation = self.createConversation(in: uiMOC)
        conversation.remoteIdentifier = conversationID
        conversation.mlsGroupID = groupID

        let commitDate = Date().addingTimeInterval(2)

        // When
        sut.scheduleCommitPendingProposals(groupID: groupID, at: commitDate)

        // Then
        conversation.commitPendingProposalDate = commitDate
    }

    func test_CommitPendingProposals_OneOverdueCommit() async throws {
        // Given
        let overdueCommitDate = Date().addingTimeInterval(-5)
        let groupID = MLSGroupID(.random())
        var conversation: ZMConversation!

        uiMOC.performAndWait {
            // A group with pending proposal in the past
            conversation = createConversation(in: uiMOC)
            conversation.mlsGroupID = groupID
            conversation.commitPendingProposalDate = overdueCommitDate
        }

        // Mocks
        mockCoreCrypto.mockCommitPendingProposals = {
            XCTAssertEqual($0, groupID.bytes)

            return CommitBundle(
                welcome: [1, 1, 1],
                commit: [2, 2, 2],
                publicGroupState: [3, 3, 3]
            )
        }

        mockActionsProvider.sendMessageMocks.append({ data in
            // The message being sent is the one we expect
            XCTAssertEqual(data, Data([2, 2, 2]))
            return []
        })

        mockActionsProvider.sendWelcomeMessageMocks.append({ data in
            // The message being sent is the one we expect
            XCTAssertEqual(data, Data([1, 1, 1]))
        })

        mockCoreCrypto.mockCommitAccepted = {
            XCTAssertEqual($0, groupID.bytes)
        }

        // When
        try await self.sut.commitPendingProposals()

        // Then
        uiMOC.performAndWait {
            XCTAssertNil(conversation.commitPendingProposalDate)
        }
    }

    func test_CommitPendingProposals_OneFutureCommit() async throws {
        // Given
        let futureCommitDate = Date().addingTimeInterval(2)
        let groupID = MLSGroupID([1, 2, 3])
        var conversation: ZMConversation!

        uiMOC.performAndWait {
            // A group with pending proposal in the future
            conversation = createConversation(in: uiMOC)
            conversation.mlsGroupID = groupID
            conversation.commitPendingProposalDate = futureCommitDate
        }

        // Mocks
        var mockCommitPendingProposalsCount = 0
        mockCoreCrypto.mockCommitPendingProposals = {
            mockCommitPendingProposalsCount += 1

            XCTAssertEqual($0, groupID.bytes)
            XCTAssertEqual(Date().timeIntervalSinceNow, futureCommitDate.timeIntervalSinceNow, accuracy: 0.1)

            return CommitBundle(
                welcome: [1, 1, 1],
                commit: [2, 2, 2],
                publicGroupState: [3, 3, 3]
            )
        }

        mockActionsProvider.sendMessageMocks.append({ data in
            // The message being sent is the one we expect
            XCTAssertEqual(data, Data([2, 2, 2]))
            return []
        })

        mockActionsProvider.sendWelcomeMessageMocks.append({ data in
            // The message being sent is the one we expect
            XCTAssertEqual(data, Data([1, 1, 1]))
        })

        mockCoreCrypto.mockCommitAccepted = {
            XCTAssertEqual($0, groupID.bytes)
        }

        // When
        try await self.sut.commitPendingProposals()

        // Then
        XCTAssertEqual(mockCommitPendingProposalsCount, 1)

        uiMOC.performAndWait {
            XCTAssertNil(conversation.commitPendingProposalDate)
        }
    }

    func test_CommitPendingProposals_MultipleCommits() async throws {
        // Given
        let overdueCommitDate = Date().addingTimeInterval(-5)
        let futureCommitDate1 = Date().addingTimeInterval(2)
        let futureCommitDate2 = Date().addingTimeInterval(5)

        let conversation1MLSGroupID = MLSGroupID([1, 2, 3])
        let conversation2MLSGroupID = MLSGroupID([4, 5, 6])
        let conversation3MLSGroupID = MLSGroupID([7, 8, 9])

        var conversation1: ZMConversation!
        var conversation2: ZMConversation!
        var conversation3: ZMConversation!

        uiMOC.performAndWait {
            // A group with pending proposal in the past
            conversation1 = createConversation(in: uiMOC)
            conversation1.mlsGroupID = conversation1MLSGroupID
            conversation1.commitPendingProposalDate = overdueCommitDate

            // A group with pending proposal in the future
            conversation2 = createConversation(in: uiMOC)
            conversation2.mlsGroupID = conversation2MLSGroupID
            conversation2.commitPendingProposalDate = futureCommitDate1

            // A group with pending proposal in the future
            conversation3 = createConversation(in: uiMOC)
            conversation3.mlsGroupID = conversation3MLSGroupID
            conversation3.commitPendingProposalDate = futureCommitDate2
        }

        // Mocks

        // Mock for the first commit
        var mockCommitPendingProposalsArguments = [Bytes]()
        mockCoreCrypto.mockCommitPendingProposals = { groupID in
            mockCommitPendingProposalsArguments.append(groupID)

            switch groupID {
            case conversation1MLSGroupID.bytes:
                // Since we don't commit in the past, we adjust the overdue date
                // to the point the commit should have been made.
                XCTAssertEqual(
                    Date().timeIntervalSinceNow,
                    overdueCommitDate.addingTimeInterval(5).timeIntervalSinceNow,
                    accuracy: 0.1
                )

            case conversation2MLSGroupID.bytes:
                XCTAssertEqual(
                    Date().timeIntervalSinceNow,
                    futureCommitDate1.timeIntervalSinceNow,
                    accuracy: 0.1
                )

            case conversation3MLSGroupID.bytes:
                XCTAssertEqual(
                    Date().timeIntervalSinceNow,
                    futureCommitDate2.timeIntervalSinceNow,
                    accuracy: 0.1
                )

            default:
                XCTFail("Unexpected group id: \(groupID)")
            }

            return CommitBundle(
                welcome: [1, 1, 1],
                commit: [2, 2, 2],
                publicGroupState: [3, 3, 3]
            )
        }

        // Mock for conversation 1
        mockActionsProvider.sendMessageMocks.append({ data in
            // The message being sent is the one we expect
            XCTAssertEqual(data, Data([2, 2, 2]))
            return []
        })

        // Mock for conversation 2
        mockActionsProvider.sendMessageMocks.append({ data in
            // The message being sent is the one we expect
            XCTAssertEqual(data, Data([2, 2, 2]))
            return []
        })

        // Mock for conversation 3
        mockActionsProvider.sendMessageMocks.append({ data in
            // The message being sent is the one we expect
            XCTAssertEqual(data, Data([2, 2, 2]))
            return []
        })

        // Mock for conversation 1
        mockActionsProvider.sendWelcomeMessageMocks.append({ data in
            // The message being sent is the one we expect
            XCTAssertEqual(data, Data([1, 1, 1]))
        })

        // Mock for conversation 2
        mockActionsProvider.sendWelcomeMessageMocks.append({ data in
            // The message being sent is the one we expect
            XCTAssertEqual(data, Data([1, 1, 1]))
        })

        // Mock for conversation 3
        mockActionsProvider.sendWelcomeMessageMocks.append({ data in
            // The message being sent is the one we expect
            XCTAssertEqual(data, Data([1, 1, 1]))
        })

        var mockCommitAcceptedArguments = [Bytes]()
        mockCoreCrypto.mockCommitAccepted = { groupID in
            mockCommitAcceptedArguments.append(groupID)

        }

        // When
        try await sut.commitPendingProposals()

        // Then pending proposals were committed in order
        XCTAssertEqual(
            mockCommitPendingProposalsArguments,
            [conversation1MLSGroupID.bytes, conversation2MLSGroupID.bytes, conversation3MLSGroupID.bytes]
        )

        XCTAssertEqual(
            mockCommitAcceptedArguments,
            [conversation1MLSGroupID.bytes, conversation2MLSGroupID.bytes, conversation3MLSGroupID.bytes]
        )

        uiMOC.performAndWait {
            XCTAssertNil(conversation1.commitPendingProposalDate)
            XCTAssertNil(conversation2.commitPendingProposalDate)
            XCTAssertNil(conversation3.commitPendingProposalDate)
        }
    }

    // MARK: Joining conversations

    func test_PerformPendingJoins_IsSuccessful() {
        // Given
        let groupID = MLSGroupID(.random())
        let epoch: UInt64 = 1

        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.mlsGroupID = groupID
        conversation.mlsStatus = .pendingJoin
        conversation.epoch = epoch

        let addProposal = Bytes.random()

        // register the group to be joined
        sut.registerPendingJoin(groupID)

        // expectation
        let expectation = XCTestExpectation(description: "Send Message")

        // mock the external add proposal returned by core crypto
        var mockNewExternalAddProposalCount = 0
        mockCoreCrypto.mockNewExternalAddProposal = {
            mockNewExternalAddProposalCount += 1

            XCTAssertEqual($0, groupID.bytes)
            XCTAssertEqual($1, epoch)

            return addProposal
        }

        // mock the action for sending the proposal & fulfill expectation
        mockActionsProvider.sendMessageMocks.append({ message in
            XCTAssertEqual(addProposal.data, message)

            expectation.fulfill()

            return []
        })

        // When
        sut.performPendingJoins()

        // Then
        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(mockNewExternalAddProposalCount, 1)
    }

    func test_PerformPendingJoins_DoesntJoinGroupNotPending() {
        // Given
        let groupID = MLSGroupID(.random())

        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.mlsGroupID = groupID
        conversation.mlsStatus = .ready

        // register the group to be joined
        sut.registerPendingJoin(groupID)

        // expectation
        let expectation = XCTestExpectation(description: "Send Message")
        expectation.isInverted = true

        // mock the external add proposal returned by core crypto
        var mockNewExternalAddProposalCount = 0
        mockCoreCrypto.mockNewExternalAddProposal = { _, _ in
            mockNewExternalAddProposalCount += 1
            return Bytes.random()
        }

        // mock the action for sending the proposal & fulfill expectation
        mockActionsProvider.sendMessageMocks.append({ _ in
            expectation.fulfill()
            return []
        })

        // When
        sut.performPendingJoins()

        // Then
        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(mockNewExternalAddProposalCount, 0)
    }

    // MARK: - Wipe Groups

    func test_WipeGroup_IsSuccessfull() {
        // Given
        let groupID = MLSGroupID(.random())

        var count = 0
        mockCoreCrypto.mockWipeConversation = { (id: ConversationId) in
            count += 1
            XCTAssertEqual(id, groupID.bytes)
        }

        // When
        sut.wipeGroup(groupID)

        // Then
        XCTAssertEqual(count, 1)
    }

    // MARK: - Key Packages

    func test_UploadKeyPackages_IsSuccessfull() {
        // Given
        let clientID = self.createSelfClient(onMOC: uiMOC).remoteIdentifier
        let keyPackages: [Bytes] = [
            [1, 2, 3],
            [4, 5, 6]
        ]

        // we need more than half the target number to have a sufficient amount
        let unsufficientKeyPackagesAmount = sut.targetUnclaimedKeyPackageCount / 3

        // expectation
        let countUnclaimedKeyPackages = self.expectation(description: "Count unclaimed key packages")
        let uploadKeyPackages = self.expectation(description: "Upload key packages")

        // mock that we queried kp count recently
        userDefaultsTestSuite.test_setLastKeyPackageCountDate(Date())

        // mock that we don't have enough unclaimed kp locally
        mockCoreCrypto.mockClientValidKeypackagesCount = {
            UInt64(unsufficientKeyPackagesAmount)
        }

        // mock keyPackages returned by core cryto
        var mockClientKeypackagesCount = 0
        mockCoreCrypto.mockClientKeypackages = {
            mockClientKeypackagesCount += 1
            XCTAssertEqual($0, UInt32(self.sut.targetUnclaimedKeyPackageCount))
            return keyPackages
        }

        // mock return value for unclaimed key packages count
        mockActionsProvider.countUnclaimedKeyPackagesMocks.append { cid in
            XCTAssertEqual(cid, clientID)
            countUnclaimedKeyPackages.fulfill()

            return unsufficientKeyPackagesAmount
        }

        mockActionsProvider.uploadKeyPackagesMocks.append { cid, kp in
            let keyPackages = keyPackages.map { $0.base64EncodedString }

            XCTAssertEqual(cid, clientID)
            XCTAssertEqual(kp, keyPackages)

            uploadKeyPackages.fulfill()
        }

        // When
        sut.uploadKeyPackagesIfNeeded()

        // Then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertEqual(mockClientKeypackagesCount, 1)
    }

    func test_UploadKeyPackages_DoesntCountUnclaimedKeyPackages_WhenNotNeeded() {
        // Given
        createSelfClient(onMOC: uiMOC)

        // expectation
        let countUnclaimedKeyPackages = XCTestExpectation(description: "Count unclaimed key packages")
        countUnclaimedKeyPackages.isInverted = true

        // mock that we queried kp count recently
        userDefaultsTestSuite.test_setLastKeyPackageCountDate(Date())

        // mock that there are enough kp locally
        mockCoreCrypto.mockClientValidKeypackagesCount = {
            UInt64(self.sut.targetUnclaimedKeyPackageCount)
        }

        mockActionsProvider.countUnclaimedKeyPackagesMocks.append { _ in
            countUnclaimedKeyPackages.fulfill()
            return 0
        }

        // When
        sut.uploadKeyPackagesIfNeeded()

        // Then
        wait(for: [countUnclaimedKeyPackages], timeout: 0.5)
    }

    func test_UploadKeyPackages_DoesntUploadKeyPackages_WhenNotNeeded() {
        // Given
        createSelfClient(onMOC: uiMOC)

        // we need more than half the target number to have a sufficient amount
        let unsufficientKeyPackagesAmount = sut.targetUnclaimedKeyPackageCount / 3

        // expectation
        let countUnclaimedKeyPackages = XCTestExpectation(description: "Count unclaimed key packages")
        let uploadKeyPackages = XCTestExpectation(description: "Upload key packages")
        uploadKeyPackages.isInverted = true

        // mock that we didn't query kp count recently
        userDefaultsTestSuite.test_setLastKeyPackageCountDate(.distantPast)

        // mock that we don't have enough unclaimed kp locally
        mockCoreCrypto.mockClientValidKeypackagesCount = {
            return UInt64(unsufficientKeyPackagesAmount)
        }

        // mock return value for unclaimed key packages count
        mockActionsProvider.countUnclaimedKeyPackagesMocks.append { _ in
            countUnclaimedKeyPackages.fulfill()
            return self.sut.targetUnclaimedKeyPackageCount
        }

        mockActionsProvider.uploadKeyPackagesMocks.append { _, _ in
            uploadKeyPackages.fulfill()
        }

        mockCoreCrypto.mockClientKeypackages = { _ in
            XCTFail("shouldn't be generating key packages")
            return []
        }

        // When
        sut.uploadKeyPackagesIfNeeded()

        // Then
        wait(for: [countUnclaimedKeyPackages, uploadKeyPackages], timeout: 0.5)
    }

    // MARK: - Welcome message

    func test_ProcessWelcomeMessage_Sucess() throws {
        // Given
        let groupID = MLSGroupID(.random())
        let message = Bytes.random().base64EncodedString

        // Mock
        mockCoreCrypto.mockProcessWelcomeMessage = { _ in
            groupID.bytes
        }

        var mockClientValidKeypackagesCountCount = 0
        mockCoreCrypto.mockClientValidKeypackagesCount = {
            mockClientValidKeypackagesCountCount += 1
            return UInt64(self.sut.targetUnclaimedKeyPackageCount)
        }

        // When
        _ = try sut.processWelcomeMessage(welcomeMessage: message)

        // Then
        XCTAssertEqual(mockClientValidKeypackagesCountCount, 1)
        XCTAssertEqual(mockStaleMLSKeyDetector.calls.keyingMaterialUpdated, [groupID])
    }

    // MARK: - Update key material

    func test_UpdateKeyMaterial_WhenInitializing() throws {
        // Given
        let group1 = MLSGroupID(.random())
        let group2 = MLSGroupID(.random())

        // Expectation
        let expectation = XCTestExpectation(description: "did update all keys")
        keyMaterialUpdatedExpectation = expectation

        // Mock
        mockStaleMLSKeyDetector.groupsWithStaleKeyingMaterial = [group1, group2]

        let commit = Bytes.random()

        var mockUpdateKeyingMaterialArguments = Set<Bytes>()
        mockCoreCrypto.mockUpdateKeyingMaterial = { groupID in
            mockUpdateKeyingMaterialArguments.insert(groupID)

            return CommitBundle(
                welcome: nil,
                commit: commit,
                publicGroupState: .random()
            )
        }

        // For the first group.
        mockActionsProvider.sendMessageMocks.append({ message in
            XCTAssertEqual(message.bytes, commit)
            return []
        })

        // For the second group.
        mockActionsProvider.sendMessageMocks.append({ message in
            XCTAssertEqual(message.bytes, commit)
            return []
        })

        var mockCommitAcceptedArguments = Set<Bytes>()
        mockCoreCrypto.mockCommitAccepted = { groupID in
            mockCommitAcceptedArguments.insert(groupID)
        }

        // When
        let sut = MLSController(
            context: uiMOC,
            coreCrypto: mockCoreCrypto,
            conversationEventProcessor: mockConversationEventProcessor,
            staleKeyMaterialDetector: mockStaleMLSKeyDetector,
            actionsProvider: mockActionsProvider,
            delegate: self
        )

        // Then
        wait(for: [expectation], timeout: 5)

        XCTAssertEqual(
            mockUpdateKeyingMaterialArguments,
            [group1.bytes, group2.bytes]
        )

        XCTAssertEqual(
            mockCommitAcceptedArguments,
            [group1.bytes, group2.bytes]
        )

        XCTAssertEqual(
            Set(mockStaleMLSKeyDetector.calls.keyingMaterialUpdated),
            Set([group1, group2])
        )

        XCTAssertEqual(
            sut.lastKeyMaterialUpdateCheck.timeIntervalSinceNow,
            Date().timeIntervalSinceNow,
            accuracy: 0.1
        )

        let timer = try XCTUnwrap(sut.keyMaterialUpdateCheckTimer)
        XCTAssertTrue(timer.isValid)

        XCTAssertEqual(
            timer.fireDate.timeIntervalSinceNow,
            Date().addingTimeInterval(.oneDay).timeIntervalSinceNow,
            accuracy: 0.1
        )
    }

}
