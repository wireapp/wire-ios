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
import WireCoreCrypto
import Combine

@testable import WireDataModel
@testable import WireDataModelSupport

class MLSServiceTests: ZMConversationTestsBase, MLSServiceDelegate {

    var sut: MLSService!
    var mockCoreCrypto: MockCoreCrypto!
    var mockSafeCoreCrypto: MockSafeCoreCrypto!
    var mockEncryptionService: MockMLSEncryptionServiceInterface!
    var mockDecryptionService: MockMLSDecryptionServiceInterface!
    var mockMLSActionExecutor: MockMLSActionExecutor!
    var mockSyncStatus: MockSyncStatus!
    var mockActionsProvider: MockMLSActionsProviderProtocol!
    var mockConversationEventProcessor: MockConversationEventProcessorProtocol!
    var mockStaleMLSKeyDetector: MockStaleMLSKeyDetector!
    var userDefaultsTestSuite: UserDefaults!
    var mockSubconversationGroupIDRepository: MockSubconversationGroupIDRepositoryInterface!

    let groupID = MLSGroupID([1, 2, 3])

    // `MLSService.init` performs actions which make it hard to assert state on mocks
    let skipSetupSUTTestNames: Set<String> = [
        "-[MLSServiceTests test_BackendPublicKeysAreFetched_WhenInitializing]",
        "-[MLSServiceTests test_UpdateKeyMaterial_WhenInitializing]",
        "-[MLSServiceTests test_SendPendingProposal_BeforeUpdatingKeyMaterial_WhenInitializing]"
    ]

    override func setUp() {
        super.setUp()
        mockCoreCrypto = MockCoreCrypto()
        mockSafeCoreCrypto = MockSafeCoreCrypto(coreCrypto: mockCoreCrypto)
        mockEncryptionService = MockMLSEncryptionServiceInterface()
        mockDecryptionService = MockMLSDecryptionServiceInterface()
        mockMLSActionExecutor = MockMLSActionExecutor()
        mockSyncStatus = MockSyncStatus()
        mockActionsProvider = MockMLSActionsProviderProtocol()
        mockConversationEventProcessor = MockConversationEventProcessorProtocol()
        mockConversationEventProcessor.processConversationEvents_MockMethod = { _ in }
        mockStaleMLSKeyDetector = MockStaleMLSKeyDetector()
        userDefaultsTestSuite = UserDefaults(suiteName: "com.wire.mls-test-suite")!
        mockSubconversationGroupIDRepository = MockSubconversationGroupIDRepositoryInterface()

        mockCoreCrypto.mockClientValidKeypackagesCount = { _ in
            return 100
        }

        mockActionsProvider.fetchBackendPublicKeysIn_MockValue = BackendMLSPublicKeys()
        mockActionsProvider.claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_MockValue = []

        if !skipSetupSUTTestNames.contains(name) {
            createSut()
        }
    }

    private func createSut() {
        didFinishInitializationExpectation = XCTestExpectation(description: "did finish initialization")
        sut = MLSService(
            context: uiMOC,
            coreCrypto: mockSafeCoreCrypto,
            encryptionService: mockEncryptionService,
            decryptionService: mockDecryptionService,
            mlsActionExecutor: mockMLSActionExecutor,
            conversationEventProcessor: mockConversationEventProcessor,
            staleKeyMaterialDetector: mockStaleMLSKeyDetector,
            userDefaults: userDefaultsTestSuite,
            actionsProvider: mockActionsProvider,
            delegate: self,
            syncStatus: mockSyncStatus,
            subconversationGroupIDRepository: mockSubconversationGroupIDRepository
        )
    }

    override func tearDown() {
        sut = nil
        didFinishInitializationExpectation = nil
        keyMaterialUpdatedExpectation = nil
        mockCoreCrypto = nil
        mockSafeCoreCrypto = nil
        mockEncryptionService = nil
        mockDecryptionService = nil
        mockMLSActionExecutor = nil
        mockSyncStatus = nil
        mockActionsProvider = nil
        mockStaleMLSKeyDetector = nil
        mockSubconversationGroupIDRepository = nil
        super.tearDown()
    }

    // MARK: - Helpers

    func dummyMemberJoinEvent() -> ZMUpdateEvent {
        let payload: NSDictionary = [
            "type": "conversation.member-join",
            "data": "foo"
        ]

        return ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!
    }

    func dummyMemberLeaveEvent() -> ZMUpdateEvent {
        let payload: NSDictionary = [
            "type": "conversation.member-leave",
            "data": "foo"
        ]

        return ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!
    }

    func createKeyPackage(userID: UUID, domain: String) -> KeyPackage {
        return KeyPackage(
            client: Data.random(byteCount: 32).base64EncodedString(),
            domain: domain,
            keyPackage: Data.random(byteCount: 32).base64EncodedString(),
            keyPackageRef: Data.random(byteCount: 32).base64EncodedString(),
            userID: userID
        )
    }

    // MARK: - mlsServiceDelegate

    var pendingProposalCommitExpectations = [MLSGroupID: XCTestExpectation]()
    var keyMaterialUpdatedExpectation: XCTestExpectation?
    var didFinishInitializationExpectation: XCTestExpectation!

    // Since SUT may schedule timers to commit pending proposals, we create expectations
    // and fulfill them when SUT informs us the commit was made.

    func mlsServiceDidCommitPendingProposal(for: MLSGroupID) {
        pendingProposalCommitExpectations[groupID]?.fulfill()
    }

    func mlsServiceDidUpdateKeyMaterialForAllGroups() {
        keyMaterialUpdatedExpectation?.fulfill()
    }

    func MLSServiceDidFinishInitialization() {
        didFinishInitializationExpectation.fulfill()
    }

    // MARK: - Public keys

    func test_BackendPublicKeysAreFetched_WhenInitializing() throws {
        // Mock
        let keys = BackendMLSPublicKeys(
            removal: .init(ed25519: Data([1, 2, 3]))
        )

        // expectations
        let fetchBackendPublicKeysExpectation = XCTestExpectation(description: "Fetch backend public keys")
        didFinishInitializationExpectation = XCTestExpectation(description: "did finish initialization")

        mockActionsProvider.fetchBackendPublicKeysIn_MockMethod = { _ in
            fetchBackendPublicKeysExpectation.fulfill()
            return keys
        }

        // When
        let sut = MLSService(
            context: uiMOC,
            coreCrypto: mockSafeCoreCrypto,
            conversationEventProcessor: mockConversationEventProcessor,
            staleKeyMaterialDetector: mockStaleMLSKeyDetector,
            userDefaults: userDefaultsTestSuite,
            actionsProvider: mockActionsProvider,
            delegate: self,
            syncStatus: mockSyncStatus
        )

        // Then
        wait(for: [fetchBackendPublicKeysExpectation, didFinishInitializationExpectation], timeout: 0.5)
        XCTAssertEqual(sut.backendPublicKeys, keys)
    }

    // MARK: - Conference info

    func test_GenerateConferenceInfo_IsSuccessful() async throws {
        // Given
        let parentGroupID = MLSGroupID.random()
        let subconversationGroupID = MLSGroupID.random()
        let secretKey = Data.random()
        let epoch: UInt64 = 1

        let member1 = MLSClientID.random()
        let member2 = MLSClientID.random()
        let member3 = MLSClientID.random()

        var mockExportSecretKeyCount = 0
        mockCoreCrypto.mockExportSecretKey = { _, _ in
            mockExportSecretKeyCount += 1
            return secretKey.bytes
        }

        var mockConversationEpochCount = 0
        mockCoreCrypto.mockConversationEpoch = { _ in
            mockConversationEpochCount += 1
            return epoch
        }

        var mockGetClientIDsCount = 0
        mockCoreCrypto.mockGetClientIds = { groupID in
            mockGetClientIDsCount += 1

            switch groupID {
            case parentGroupID.bytes:
                return [member1, member2, member3].compactMap {
                    $0.rawValue.utf8Data?.bytes
                }

            case subconversationGroupID.bytes:
                return [member1, member2].compactMap {
                    $0.rawValue.utf8Data?.bytes
                }

            default:
                return []
            }
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        let conferenceInfo = try await sut.generateConferenceInfo(
            parentGroupID: parentGroupID,
            subconversationGroupID: subconversationGroupID
        )

        // Then
        XCTAssertEqual(mockExportSecretKeyCount, 1)
        XCTAssertEqual(mockConversationEpochCount, 1)
        XCTAssertEqual(mockGetClientIDsCount, 2)

        let expectedConferenceInfo = MLSConferenceInfo(
            epoch: epoch,
            keyData: secretKey,
            members: [
                MLSConferenceInfo.Member(id: member1, isInSubconversation: true),
                MLSConferenceInfo.Member(id: member2, isInSubconversation: true),
                MLSConferenceInfo.Member(id: member3, isInSubconversation: false)
            ]
        )

        XCTAssertEqual(conferenceInfo, expectedConferenceInfo)
    }

    typealias ConferenceInfoError = MLSService.MLSConferenceInfoError

    func test_GenerateConferenceInfo_Fails() async {
        // Given
        let parentGroupID = MLSGroupID.random()
        let subconversationGroupID = MLSGroupID.random()

        var mockConversationEpochCount = 0
        mockCoreCrypto.mockConversationEpoch = { _ in
            mockConversationEpochCount += 1
            return 0
        }

        mockCoreCrypto.mockExportSecretKey = { _, _ in
            throw CryptoError.ConversationNotFound(message: "foo")
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When / Then
        await assertItThrows(error: ConferenceInfoError.failedToGenerateConferenceInfo) {
            _ = try await sut.generateConferenceInfo(
                parentGroupID: parentGroupID,
                subconversationGroupID: subconversationGroupID
            )
        }
    }

    // MARK: - Message Encryption

    func test_Encrypt_UsesEncyptionService() throws {
        // Given
        let message = "foo"
        let groupID = MLSGroupID.random()
        let subconversationType = SubgroupType.conference

        let mockResult = MLSDecryptResult.message(.random(), .random(length: 3))

        mockDecryptionService.decryptMessageForSubconversationType_MockValue = mockResult

        // wait for `MLSService.init`'s async operations
        wait(for: [didFinishInitializationExpectation], timeout: 1)

        // When
        let result = try sut.decrypt(
            message: message,
            for: groupID,
            subconversationType: subconversationType
        )

        // Then
        XCTAssertEqual(mockDecryptionService.decryptMessageForSubconversationType_Invocations.count, 1)
        let invocation = mockDecryptionService.decryptMessageForSubconversationType_Invocations.element(atIndex: 0)
        XCTAssertEqual(invocation?.message, message)
        XCTAssertEqual(invocation?.groupID, groupID)
        XCTAssertEqual(invocation?.subconversationType, subconversationType)
        XCTAssertEqual(result, mockResult)
    }

    // MARK: - Message Decryption

    func test_Decrypt_UsesDecyptionService() throws {
        // Given
        let message = "foo"
        let groupID = MLSGroupID.random()
        let subconversationType = SubgroupType.conference

        let mockResult = MLSDecryptResult.message(.random(), .random(length: 3))
        mockDecryptionService.decryptMessageForSubconversationType_MockValue = mockResult

        // wait for `MLSService.init`'s async operations
        wait(for: [didFinishInitializationExpectation], timeout: 1)

        // When
        let result = try sut.decrypt(
            message: message,
            for: groupID,
            subconversationType: subconversationType
        )

        // Then
        XCTAssertEqual(mockDecryptionService.decryptMessageForSubconversationType_Invocations.count, 1)
        let invocation = mockDecryptionService.decryptMessageForSubconversationType_Invocations.element(atIndex: 0)
        XCTAssertEqual(invocation?.message, message)
        XCTAssertEqual(invocation?.groupID, groupID)
        XCTAssertEqual(invocation?.subconversationType, subconversationType)
        XCTAssertEqual(result, mockResult)
    }

    func test_Decrypt_RepairsConversationOnWrongEpochError() throws {
        // Given
        let conversation = createConversation(outOfSync: true).conversation
        let groupID = try XCTUnwrap(conversation.mlsGroupID)
        let message = "foo"
        let error = MLSDecryptionService.MLSMessageDecryptionError.wrongEpoch
        mockDecryptionService.decryptMessageForSubconversationType_MockError = error

        let expectation = XCTestExpectation(description: "repaired conversation")

        setMocksForConversationRepair(
            parentGroupID: groupID,
            epoch: conversation.epoch + 1,
            onJoinGroup: { joinedGroupID in
                XCTAssertEqual(groupID, joinedGroupID)
                expectation.fulfill()
            }
        )

        // wait for `MLSService.init`'s async operations
        wait(for: [didFinishInitializationExpectation], timeout: 1)

        // When
        _ = try? sut.decrypt(
            message: message,
            for: groupID,
            subconversationType: nil
        )

        // Then
        wait(for: [expectation], timeout: 0.5)
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)
    }

    // MARK: - Create group

    func test_CreateGroup_IsSuccessful() throws {
        // Given
        let groupID = MLSGroupID(Data([1, 2, 3]))
        let removalKey = Data([1, 2, 3])

        mockActionsProvider.fetchBackendPublicKeysIn_MockValue = .init(
            removal: .init(ed25519: removalKey)
        )

        var mockCreateConversationCount = 0
        mockCoreCrypto.mockCreateConversation = {
            mockCreateConversationCount += 1

            XCTAssertEqual($0, groupID.bytes)
            XCTAssertEqual($1, .basic)
            XCTAssertEqual($2, ConversationConfiguration(
                ciphersuite: CiphersuiteName.mls128Dhkemx25519Aes128gcmSha256Ed25519.rawValue,
                externalSenders: [removalKey.bytes],
                custom: .init(keyRotationSpan: nil, wirePolicy: nil)
            ))
        }

        // wait for `MLSService.init`'s async operations
        wait(for: [didFinishInitializationExpectation], timeout: 1)

        // When
        XCTAssertNoThrow(try sut.createGroup(for: groupID))

        // Then
        XCTAssertEqual(mockCreateConversationCount, 1)
        XCTAssertEqual(mockStaleMLSKeyDetector.calls.keyingMaterialUpdated, [groupID])
    }

    func test_CreateGroup_ThrowsError() throws {
        // Given
        let groupID = MLSGroupID(Data([1, 2, 3]))
        let config = ConversationConfiguration(
            ciphersuite: CiphersuiteName.mls128Dhkemx25519Aes128gcmSha256Ed25519.rawValue,
            externalSenders: [],
            custom: .init(keyRotationSpan: nil, wirePolicy: nil)
        )

        var mockCreateConversationCount = 0
        mockCoreCrypto.mockCreateConversation = {
            mockCreateConversationCount += 1

            XCTAssertEqual($0, groupID.bytes)
            XCTAssertEqual($1, .basic)
            XCTAssertEqual($2, config)

            throw CryptoError.MalformedIdentifier(message: "bad id")
        }

        // wait for `MLSService.init`'s async operations
        wait(for: [didFinishInitializationExpectation], timeout: 1)

        // when / then
        assertItThrows(error: MLSService.MLSGroupCreationError.failedToCreateGroup) {
            try sut.createGroup(for: groupID)
        }

        // Then
        XCTAssertEqual(mockCreateConversationCount, 1)
    }

    // MARK: - Adding participants

    func test_AddingMembersToConversation_Successfully() async throws {
        // Given
        let id = UUID.create()
        let domain = "example.com"
        let mlsGroupID = MLSGroupID(Data([1, 2, 3]))
        let mlsUser = [MLSUser(id: id, domain: domain)]

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in
            throw MLSActionExecutor.Error.noPendingProposals
        }

        // Mock claiming a key package.
        var keyPackage: KeyPackage!
        mockActionsProvider.claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_MockMethod = { userID, _, _, _ in
            keyPackage = self.createKeyPackage(userID: userID, domain: domain)
            return [keyPackage]
        }

        // Mock adding memebers to the conversation.
        var mockAddMembersArguments = [([Invitee], MLSGroupID)]()
        let updateEvent = dummyMemberJoinEvent()

        mockMLSActionExecutor.mockAddMembers = {
            mockAddMembersArguments.append(($0, $1))
            return [updateEvent]
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        try await sut.addMembersToConversation(with: mlsUser, for: mlsGroupID)

        // Then we added the members.
        XCTAssertEqual(mockAddMembersArguments.count, 1)
        XCTAssertEqual(mockAddMembersArguments.first?.0, [Invitee(from: keyPackage)])
        XCTAssertEqual(mockAddMembersArguments.first?.1, mlsGroupID)

        // And processd the update event.
        let processConversationEventsCalls = self.mockConversationEventProcessor.processConversationEvents_Invocations
        XCTAssertEqual(processConversationEventsCalls.count, 1)
        XCTAssertEqual(processConversationEventsCalls[0], [updateEvent])
    }

    func test_CommitPendingProposals_BeforeAddingMembersToConversation_Successfully() async throws {
        // Given
        let groupID = MLSGroupID.random()
        var conversation: ZMConversation!
        let futureCommitDate = Date().addingTimeInterval(2)

        await uiMOC.perform { [self] in
            // A group with pending proposal in the future
            conversation = createConversation(in: uiMOC)
            conversation.mlsGroupID = groupID
            conversation.commitPendingProposalDate = futureCommitDate
        }

        // Mock commiting a pending proposal
        var mockCommitPendingProposalsArgument = [MLSGroupID]()
        let updateEvent1 = dummyMemberJoinEvent()
        mockMLSActionExecutor.mockCommitPendingProposals = {
            mockCommitPendingProposalsArgument.append($0)
            return [updateEvent1]
        }

        // The user to add.
        let domain = "example.com"
        let id = UUID.create()
        let mlsUser = [MLSUser(id: id, domain: domain)]

        // Mock claiming a key package.
        var keyPackage: KeyPackage!
        mockActionsProvider.claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_MockMethod = { userID, _, _, _ in
            keyPackage = self.createKeyPackage(userID: userID, domain: domain)
            return [keyPackage]
        }

        // Mock adding memebers to the conversation.
        var mockAddMembersArguments = [([Invitee], MLSGroupID)]()
        let updateEvent2 = dummyMemberJoinEvent()

        mockMLSActionExecutor.mockAddMembers = {
            mockAddMembersArguments.append(($0, $1))
            return [updateEvent2]
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        try await sut.addMembersToConversation(with: mlsUser, for: groupID)

        // Then we committed pending proposals.
        XCTAssertEqual(mockCommitPendingProposalsArgument, [groupID])

        await uiMOC.perform {
            XCTAssertNil(conversation.commitPendingProposalDate)
        }

        // Then we added the members.
        XCTAssertEqual(mockAddMembersArguments.count, 1)
        XCTAssertEqual(mockAddMembersArguments.first?.0, [Invitee(from: keyPackage)])
        XCTAssertEqual(mockAddMembersArguments.first?.1, groupID)

        // We processed the conversation events.
        let processConversationEventsCalls = self.mockConversationEventProcessor.processConversationEvents_Invocations
        XCTAssertEqual(processConversationEventsCalls, [[updateEvent1], [updateEvent2]])
    }

    func test_AddingMembersToConversation_ThrowsNoParticipantsToAdd() async {
        // Given
        let mlsGroupID = MLSGroupID(Data([1, 2, 3]))

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in
            throw MLSActionExecutor.Error.noPendingProposals
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // when / then
        await assertItThrows(error: MLSService.MLSAddMembersError.noMembersToAdd) {
            try await sut.addMembersToConversation(with: [], for: mlsGroupID)
        }
    }

    func test_AddingMembersToConversation_ClaimKeyPackagesFails() async {
        // Given
        let domain = "example.com"
        let id = UUID.create()
        let mlsGroupID = MLSGroupID(Data([1, 2, 3]))
        let mlsUser: [MLSUser] = [MLSUser(id: id, domain: domain)]

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in
            throw MLSActionExecutor.Error.noPendingProposals
        }

        // Mock failure for claiming key packages.
        mockActionsProvider.claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_MockError = ClaimMLSKeyPackageAction.Failure.missingDomain

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // Then
        await assertItThrows(error: MLSService.MLSAddMembersError.failedToClaimKeyPackages) {
            // When
            try await sut.addMembersToConversation(with: mlsUser, for: mlsGroupID)
        }
    }

    func test_AddingMembersToConversation_ExecutorFails() async {
        // Given
        let domain = "example.com"
        let id = UUID.create()
        let mlsGroupID = MLSGroupID(Data([1, 2, 3]))
        let mlsUser: [MLSUser] = [MLSUser(id: id, domain: domain)]

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in
            throw MLSActionExecutor.Error.noPendingProposals
        }

        // Mock key package.
        var keyPackage: KeyPackage!
        mockActionsProvider.claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_MockMethod = { userID, _, _, _ in
            keyPackage = self.createKeyPackage(userID: userID, domain: domain)
            return [keyPackage]
        }

        mockMLSActionExecutor.mockAddMembers = { _, _ in
            throw MLSActionExecutor.Error.failedToGenerateCommit
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // when / then
        await assertItThrows(error: MLSActionExecutor.Error.failedToGenerateCommit) {
            try await sut.addMembersToConversation(with: mlsUser, for: mlsGroupID)
        }
    }

    // MARK: - Remove participants

    func test_RemoveMembersFromConversation_IsSuccessful() async throws {
        // Given
        let id = UUID.create().uuidString
        let domain = "example.com"
        let clientID = UUID.create().uuidString
        let mlsGroupID = MLSGroupID(Data([1, 2, 3]))
        let mlsClientID = MLSClientID(userID: id, clientID: clientID, domain: domain)

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in
            throw MLSActionExecutor.Error.noPendingProposals
        }

        // Mock removing clients from the group.
        var mockRemoveClientsArguments = [([ClientId], MLSGroupID)]()
        let updateEvent = dummyMemberLeaveEvent()

        mockMLSActionExecutor.mockRemoveClients = {
            mockRemoveClientsArguments.append(($0, $1))
            return [updateEvent]
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        try await sut.removeMembersFromConversation(with: [mlsClientID], for: mlsGroupID)

        // Then we removed the clients.
        let clientIDBytes = try XCTUnwrap(mlsClientID.rawValue.data(using: .utf8)?.bytes)
        XCTAssertEqual(mockRemoveClientsArguments.count, 1)
        XCTAssertEqual(mockRemoveClientsArguments.first?.0, [clientIDBytes])
        XCTAssertEqual(mockRemoveClientsArguments.first?.1, mlsGroupID)

        // Then we process the update event.
        let processConversationEventsCalls = self.mockConversationEventProcessor.processConversationEvents_Invocations
        XCTAssertEqual(processConversationEventsCalls, [[updateEvent]])
    }

    func test_CommitPendingProposals_BeforeRemoveMembersFromConversation_IsSuccessful() async throws {
        // Given
        let groupID = MLSGroupID.random()
        var conversation: ZMConversation!
        let futureCommitDate = Date().addingTimeInterval(2)

        await uiMOC.perform { [self] in
            // A group with pending proposal in the future
            conversation = createConversation(in: uiMOC)
            conversation.mlsGroupID = groupID
            conversation.commitPendingProposalDate = futureCommitDate
        }

        // Mock commiting a pending proposal.
        var mockCommitPendingProposalsArgument = [MLSGroupID]()
        let updateEvent1 = dummyMemberJoinEvent()
        mockMLSActionExecutor.mockCommitPendingProposals = {
            mockCommitPendingProposalsArgument.append($0)
            return [updateEvent1]
        }

        // The user to remove.
        let id = UUID.create().uuidString
        let domain = "example.com"
        let clientID = UUID.create().uuidString
        let mlsClientID = MLSClientID(userID: id, clientID: clientID, domain: domain)

        // Mock removing clients from the group.
        var mockRemoveClientsArguments = [([ClientId], MLSGroupID)]()
        let updateEvent2 = dummyMemberLeaveEvent()

        mockMLSActionExecutor.mockRemoveClients = {
            mockRemoveClientsArguments.append(($0, $1))
            return [updateEvent2]
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        try await sut.removeMembersFromConversation(with: [mlsClientID], for: groupID)

        // Then we committed pending proposals.
        XCTAssertEqual(mockCommitPendingProposalsArgument, [groupID])

        await uiMOC.perform {
            XCTAssertNil(conversation.commitPendingProposalDate)
        }

        // Then we removed the clients.
        let clientIDBytes = try XCTUnwrap(mlsClientID.rawValue.data(using: .utf8)?.bytes)
        XCTAssertEqual(mockRemoveClientsArguments.count, 1)
        XCTAssertEqual(mockRemoveClientsArguments.first?.0, [clientIDBytes])
        XCTAssertEqual(mockRemoveClientsArguments.first?.1, groupID)

        // Then we process the update events.
        let processConversationEventsCalls = self.mockConversationEventProcessor.processConversationEvents_Invocations
        XCTAssertEqual(processConversationEventsCalls, [[updateEvent1], [updateEvent2]])
    }

    func test_RemovingMembersToConversation_ThrowsNoClientsToRemove() async {
        // Given
        let mlsGroupID = MLSGroupID(Data([1, 2, 3]))

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in
            throw MLSActionExecutor.Error.noPendingProposals
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When / Then
        await assertItThrows(error: MLSService.MLSRemoveParticipantsError.noClientsToRemove) {
            try await sut.removeMembersFromConversation(with: [], for: mlsGroupID)
        }
    }

    func test_RemovingMembersToConversation_ExecutorFails() async {
        // Given
        let id = UUID.create().uuidString
        let domain = "example.com"
        let clientID = UUID.create().uuidString
        let mlsGroupID = MLSGroupID(Data([1, 2, 3]))
        let mlsClientID = MLSClientID(userID: id, clientID: clientID, domain: domain)

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in
            throw MLSActionExecutor.Error.noPendingProposals
        }

        // Mock executor error.
        mockMLSActionExecutor.mockRemoveClients = { _, _ in
            throw MLSActionExecutor.Error.failedToGenerateCommit
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When / Then
        await assertItThrows(error: MLSActionExecutor.Error.failedToGenerateCommit) {
            try await sut.removeMembersFromConversation(with: [mlsClientID], for: mlsGroupID)
        }
    }

    // MARK: - Pending proposals

    func test_CommitPendingProposals_NoProposalsExist() async throws {
        // Given
        let overdueCommitDate = Date().addingTimeInterval(-5)
        let groupID = MLSGroupID.random()
        var conversation: ZMConversation!

        await uiMOC.perform { [self] in
            // A group with pending proposal in the past.
            conversation = createConversation(in: uiMOC)
            conversation.mlsGroupID = groupID
            conversation.commitPendingProposalDate = overdueCommitDate
        }

        // Mock no subconversations
        mockSubconversationGroupIDRepository.fetchSubconversationGroupIDForTypeParentGroupID_MockValue = .some(nil)

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in
            throw MLSActionExecutor.Error.noPendingProposals
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        try await self.sut.commitPendingProposals()

        // Then we cleared the pending proposal date.
        await uiMOC.perform {
            XCTAssertNil(conversation.commitPendingProposalDate)
        }
    }

    func test_CommitPendingProposals_OneOverdueCommit() async throws {
        // Given
        let overdueCommitDate = Date().addingTimeInterval(-5)
        let groupID = MLSGroupID.random()
        var conversation: ZMConversation!

        await uiMOC.perform { [self] in
            // A group with pending proposal in the past.
            conversation = createConversation(in: uiMOC)
            conversation.mlsGroupID = groupID
            conversation.commitPendingProposalDate = overdueCommitDate
        }

        // Mock no subconversations
        mockSubconversationGroupIDRepository.fetchSubconversationGroupIDForTypeParentGroupID_MockValue = .some(nil)

        // Mock committing pending proposal.
        var mockCommitPendingProposalArguments = [(MLSGroupID, Date)]()
        let updateEvent = dummyMemberJoinEvent()

        mockMLSActionExecutor.mockCommitPendingProposals = {
            mockCommitPendingProposalArguments.append(($0, Date()))
            return [updateEvent]
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        try await self.sut.commitPendingProposals()

        // Then we committed the pending proposal immediately.
        let (id, commitTime) = try XCTUnwrap(mockCommitPendingProposalArguments.first)
        XCTAssertEqual(mockCommitPendingProposalArguments.count, 1)
        XCTAssertEqual(id, groupID)
        XCTAssertEqual(commitTime.timeIntervalSinceNow, Date().timeIntervalSinceNow, accuracy: 0.1)

        await uiMOC.perform {
            XCTAssertNil(conversation.commitPendingProposalDate)
        }

        // Then we processed the update event.
        XCTAssertEqual(mockConversationEventProcessor.processConversationEvents_Invocations, [[updateEvent]])
    }

    func test_CommitPendingProposals_OneFutureCommit() async throws {
        // Given
        let futureCommitDate = Date().addingTimeInterval(2)
        let groupID = MLSGroupID([1, 2, 3])
        var conversation: ZMConversation!

        await uiMOC.perform { [self] in
            // A group with pending proposal in the future
            conversation = createConversation(in: uiMOC)
            conversation.mlsGroupID = groupID
            conversation.commitPendingProposalDate = futureCommitDate
        }

        // Mock no subconversations
        mockSubconversationGroupIDRepository.fetchSubconversationGroupIDForTypeParentGroupID_MockValue = .some(nil)

        // Mock committing pending proposal.
        var mockCommitPendingProposalArguments = [(MLSGroupID, Date)]()
        let updateEvent = dummyMemberJoinEvent()

        mockMLSActionExecutor.mockCommitPendingProposals = {
            mockCommitPendingProposalArguments.append(($0, Date()))
            return [updateEvent]
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        try await self.sut.commitPendingProposals()

        // Then we committed the proposal at the right time.
        let (id, commitTime) = try XCTUnwrap(mockCommitPendingProposalArguments.first)
        XCTAssertEqual(mockCommitPendingProposalArguments.count, 1)
        XCTAssertEqual(id, groupID)
        XCTAssertEqual(commitTime.timeIntervalSinceNow, futureCommitDate.timeIntervalSinceNow, accuracy: 0.1)

        await uiMOC.perform {
            XCTAssertNil(conversation.commitPendingProposalDate)
        }

        // Then we processed the update event.
        XCTAssertEqual(mockConversationEventProcessor.processConversationEvents_Invocations, [[updateEvent]])
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

        await uiMOC.perform { [self] in
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

        // Mock no subconversations
        mockSubconversationGroupIDRepository.fetchSubconversationGroupIDForTypeParentGroupID_MockValue = .some(nil)

        // Mock committing pending proposal.
        var mockCommitPendingProposalArguments = [(MLSGroupID, Date)]()
        let updateEvent1 = dummyMemberJoinEvent()
        let updateEvent2 = dummyMemberJoinEvent()
        let updateEvent3 = dummyMemberJoinEvent()

        mockMLSActionExecutor.mockCommitPendingProposals = {
            mockCommitPendingProposalArguments.append(($0, Date()))

            switch mockCommitPendingProposalArguments.count {
            case 1: return [updateEvent1]
            case 2: return [updateEvent2]
            case 3: return [updateEvent3]
            default: return []
            }
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        try await sut.commitPendingProposals()

        // Then pending proposals were committed in order at the right times.
        XCTAssertEqual(mockCommitPendingProposalArguments.count, 3)

        // Commit 1
        let (id1, commitTime1) = try XCTUnwrap(mockCommitPendingProposalArguments.element(atIndex: 0))
        XCTAssertEqual(id1, conversation1MLSGroupID)
        XCTAssertEqual(
            commitTime1.timeIntervalSinceNow,
            overdueCommitDate.addingTimeInterval(5).timeIntervalSinceNow,
            accuracy: 0.1
        )

        // Commit 2
        let (id2, commitTime2) = try XCTUnwrap(mockCommitPendingProposalArguments.element(atIndex: 1))
        XCTAssertEqual(id2, conversation2MLSGroupID)
        XCTAssertEqual(
            commitTime2.timeIntervalSinceNow,
            futureCommitDate1.timeIntervalSinceNow,
            accuracy: 0.1
        )

        // Commit 3
        let (id3, commitTime3) = try XCTUnwrap(mockCommitPendingProposalArguments.element(atIndex: 2))
        XCTAssertEqual(id3, conversation3MLSGroupID)
        XCTAssertEqual(
            commitTime3.timeIntervalSinceNow,
            futureCommitDate2.timeIntervalSinceNow,
            accuracy: 0.1
        )

        // Then all conversations have no more commit dates.
        await uiMOC.perform {
            XCTAssertNil(conversation1.commitPendingProposalDate)
            XCTAssertNil(conversation2.commitPendingProposalDate)
            XCTAssertNil(conversation3.commitPendingProposalDate)
        }

        // Then we processed the update event.
        XCTAssertEqual(
            mockConversationEventProcessor.processConversationEvents_Invocations,
            [[updateEvent1], [updateEvent2], [updateEvent3]]
        )
    }

    func test_CommitPendingProposals_ForSubconversation() async throws {
        // Given
        let overdueCommitDate = Date().addingTimeInterval(-5)
        let parentGroupdID = MLSGroupID.random()
        let subgroupID = MLSGroupID.random()
        var conversation: ZMConversation!

        await uiMOC.perform { [self] in
            // A group with pending proposal in the past.
            conversation = createConversation(in: uiMOC)
            conversation.mlsGroupID = parentGroupdID
            conversation.commitPendingProposalDate = overdueCommitDate
        }

        // Mock subconversation
        mockSubconversationGroupIDRepository.fetchSubconversationGroupIDForTypeParentGroupID_MockValue = subgroupID

        // Mock committing pending proposal.
        var mockCommitPendingProposalArguments = [(MLSGroupID, Date)]()

        mockMLSActionExecutor.mockCommitPendingProposals = {
            mockCommitPendingProposalArguments.append(($0, Date()))
            return []
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        try await self.sut.commitPendingProposals()

        // Then we asked for the subgroup id
        let subgroupInvocations = mockSubconversationGroupIDRepository.fetchSubconversationGroupIDForTypeParentGroupID_Invocations
        XCTAssertEqual(subgroupInvocations.count, 1)
        XCTAssertEqual(subgroupInvocations.first?.type, .conference)
        XCTAssertEqual(subgroupInvocations.first?.parentGroupID, parentGroupdID)

        // Then we try to commit pending propsoals twice, once for the subgroup, once for the parent
        XCTAssertEqual(mockCommitPendingProposalArguments.count, 2)
        let (id1, commitTime1) = try XCTUnwrap(mockCommitPendingProposalArguments.first)
        XCTAssertEqual(id1, subgroupID)
        XCTAssertEqual(commitTime1.timeIntervalSinceNow, Date().timeIntervalSinceNow, accuracy: 0.1)

        let (id2, commitTime2) = try XCTUnwrap(mockCommitPendingProposalArguments.last)
        XCTAssertEqual(id2, parentGroupdID)
        XCTAssertEqual(commitTime2.timeIntervalSinceNow, Date().timeIntervalSinceNow, accuracy: 0.1)

        await uiMOC.perform {
            XCTAssertNil(conversation.commitPendingProposalDate)
        }
    }

    // MARK: - Joining conversations

    func test_PerformPendingJoins_IsSuccessful() {
        // Given
        let groupID = MLSGroupID.random()
        let conversationID = UUID.create()
        let domain = "example.domain.com"
        let publicGroupState = Data()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = conversationID
        conversation.domain = domain
        conversation.mlsGroupID = groupID
        conversation.mlsStatus = .pendingJoin

        // TODO: Mock properly
        let mockUpdateEvents = [ZMUpdateEvent]()

        // register the group to be joined
        sut.registerPendingJoin(groupID)

        // expectation
        let expectation = XCTestExpectation(description: "Send Message")

        // mock fetching group info
        mockActionsProvider.fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockValue = publicGroupState

        // mock joining group
        var joinGroupArguments = [(groupID: MLSGroupID, groupState: Data)]()
        mockMLSActionExecutor.mockJoinGroup = {
            joinGroupArguments.append(($0, $1))
            return mockUpdateEvents
        }

        // mock processing conversation events
        var processConversationEventsArguments = [[ZMUpdateEvent]]()
        mockConversationEventProcessor.processConversationEvents_MockMethod = {
            processConversationEventsArguments.append($0)
            expectation.fulfill()
        }

        // wait for `MLSService.init`'s async operations
        wait(for: [didFinishInitializationExpectation], timeout: 1)

        // When
        sut.performPendingJoins()

        // Then
        wait(for: [expectation], timeout: 0.5)

        // it fetches public group state
        let groupStateInvocations = mockActionsProvider.fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_Invocations
        XCTAssertEqual(groupStateInvocations.count, 1)
        XCTAssertEqual(groupStateInvocations.first?.conversationId, conversationID)
        XCTAssertEqual(groupStateInvocations.first?.domain, domain)

        // it asks executor to join group
        XCTAssertEqual(joinGroupArguments.count, 1)
        XCTAssertEqual(joinGroupArguments.first?.groupID, groupID)
        XCTAssertEqual(joinGroupArguments.first?.groupState, publicGroupState)

        // it sets conversation state to ready
        XCTAssertEqual(conversation.mlsStatus, .ready)

        // it processes conversation events
        XCTAssertEqual(processConversationEventsArguments.count, 1)
        XCTAssertEqual(processConversationEventsArguments.first, mockUpdateEvents)
    }

    func test_PerformPendingJoins_Retries() {
        test_PerformPendingJoinsRecovery(.retry)
    }

    func test_PerformPendingJoins_GivesUp() {
        test_PerformPendingJoinsRecovery(.giveUp)
    }

    private func test_PerformPendingJoinsRecovery(_ recovery: MLSActionExecutor.ExternalCommitErrorRecovery) {
        // Given
        let shouldRetry = recovery == .retry
        let groupID = MLSGroupID.random()
        let conversationID = UUID.create()
        let domain = "example.domain.com"
        let groupInfo = Data()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = conversationID
        conversation.domain = domain
        conversation.mlsGroupID = groupID
        conversation.mlsStatus = .pendingJoin

        // register the group to be joined
        sut.registerPendingJoin(groupID)

        // set up expectations
        let expectation = XCTestExpectation(description: "Send Message")
        expectation.isInverted = !shouldRetry

        // mock fetching group info
        mockActionsProvider.fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockValue = groupInfo

        // mock joining group
        var joinGroupCount = 0
        mockMLSActionExecutor.mockJoinGroup = { _, _ in
            joinGroupCount += 1

            if joinGroupCount == 1 {
                throw MLSActionExecutor.Error.failedToSendExternalCommit(recovery: recovery)
            }

            return []
        }

        // mock processing conversation events
        var processConversationEventsCount = 0
        mockConversationEventProcessor.processConversationEvents_MockMethod = { _ in
            processConversationEventsCount += 1
            expectation.fulfill()
        }

        // wait for `MLSService.init`'s async operations
        wait(for: [didFinishInitializationExpectation], timeout: 1)

        // When
        sut.performPendingJoins()

        // Then
        wait(for: [expectation], timeout: 0.5)

        // it fetches group info
        let groupInfoInvocations = mockActionsProvider.fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_Invocations
        XCTAssertEqual(groupInfoInvocations.count, shouldRetry ? 2 : 1)

        // it asks executor to join group
        XCTAssertEqual(joinGroupCount, shouldRetry ? 2 : 1)

        // it sets conversation state to ready
        XCTAssertEqual(conversation.mlsStatus, shouldRetry ? .ready : .pendingJoin)

        // it processes conversation events
        XCTAssertEqual(processConversationEventsCount, shouldRetry ? 1 : 0)
    }

    func test_PerformPendingJoins_DoesntJoinGroupNotPending() {
        // Given
        let groupID = MLSGroupID.random()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.mlsGroupID = groupID
        conversation.remoteIdentifier = UUID.create()
        conversation.domain = "domain.com"
        conversation.mlsStatus = .ready

        // register the group to be joined
        sut.registerPendingJoin(groupID)

        // expectation
        let expectation = XCTestExpectation(description: "Send Message")
        expectation.isInverted = true

        // mock fetching group info
        mockActionsProvider.fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockValue = Data()

        // mock joining group
        mockMLSActionExecutor.mockJoinGroup = { _, _ in
            expectation.fulfill()
            return []
        }

        // wait for `MLSService.init`'s async operations
        wait(for: [didFinishInitializationExpectation], timeout: 1)

        // When
        sut.performPendingJoins()

        // Then
        wait(for: [expectation], timeout: 0.5)

        let groupInfoInvocations = mockActionsProvider.fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_Invocations
        XCTAssertEqual(groupInfoInvocations.count, 0)
    }

    // MARK: - Handling out of sync conversations

    func test_RepairOutOfSyncConversations_RejoinsOutOfSyncConversations() {
        // GIVEN
        let conversationAndOutOfSyncTuples = [
            createConversation(outOfSync: true),
            createConversation(outOfSync: true),
            createConversation(outOfSync: false)
        ]

        // mock conversation epoch
        mockCoreCrypto.mockConversationEpoch = { groupID in
            guard let tuple = conversationAndOutOfSyncTuples.first(
                where: { $0.conversation.mlsGroupID?.bytes == groupID }
            ) else {
                return 1
            }

            let epoch = tuple.conversation.epoch
            return tuple.isOutOfSync ? epoch + 1 : epoch
        }

        // mock fetching group info
        mockActionsProvider.fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockValue = Data()

        // mock joining group
        let expectations = expectations(from: conversationAndOutOfSyncTuples)
        mockMLSActionExecutor.mockJoinGroup = { groupID, _ in
            expectations[groupID]?.fulfill()
            return []
        }

        // wait for `MLSService.init`'s async operations
        wait(for: [didFinishInitializationExpectation], timeout: 1)

        // WHEN
        sut.repairOutOfSyncConversations()

        // THEN
        wait(for: Array(expectations.values), timeout: 1.5)
    }

    func test_FetchAndRepairConversation_RejoinsOutOfSyncConversation() throws {
        // GIVEN
        let conversation = createConversation(outOfSync: true).conversation
        let groupID = try XCTUnwrap(conversation.mlsGroupID)
        let expectation = XCTestExpectation(description: "rejoined conversation")

        setMocksForConversationRepair(
            parentGroupID: groupID,
            epoch: conversation.epoch + 1,
            onJoinGroup: { joinedGroupID in
                XCTAssertEqual(groupID, joinedGroupID)
                expectation.fulfill()
            }
        )

        // wait for `MLSService.init`'s async operations
        wait(for: [didFinishInitializationExpectation], timeout: 1)

        // WHEN
        sut.fetchAndRepairGroupIfPossible(with: groupID)

        // THEN
        // Verify expectation that the conversation was rejoined
        wait(for: [expectation], timeout: 0.5)
        // Wait for groups that need the current context before its deallocated
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }

    func test_FetchAndRepairConversation_DoesNothingIfConversationIsNotOutOfSync() throws {
        // GIVEN
        let conversation = createConversation(outOfSync: true).conversation
        let groupID = try XCTUnwrap(conversation.mlsGroupID)

        let expectation = XCTestExpectation(description: "didn't rejoin conversation")
        expectation.isInverted = true

        setMocksForConversationRepair(
            parentGroupID: groupID,
            epoch: conversation.epoch,
            onJoinGroup: { _ in
                expectation.fulfill()
            }
        )

        // wait for `MLSService.init`'s async operations
        wait(for: [didFinishInitializationExpectation], timeout: 1)

        // WHEN
        sut.fetchAndRepairGroupIfPossible(with: groupID)

        // THEN
        // Verify expectation that the conversation was NOT rejoined
        wait(for: [expectation], timeout: 0.5)
    }

    func test_FetchAndRepairConversation_RejoinsOutOfSyncSubgroup() throws {
        // GIVEN
        let conversation = createConversation(outOfSync: true).conversation
        let groupID = try XCTUnwrap(conversation.mlsGroupID)
        let subgroupID = MLSGroupID.random()

        let subgroup = MLSSubgroup(
            cipherSuite: 0,
            epoch: 1,
            epochTimestamp: Date(),
            groupID: subgroupID,
            members: [],
            parentQualifiedID: try XCTUnwrap(conversation.qualifiedID)
        )

        let expectation = XCTestExpectation(description: "rejoined subgroup")

        setMocksForConversationRepair(
            parentGroupID: groupID,
            epoch: UInt64(subgroup.epoch + 1),
            subgroup: subgroup,
            onJoinGroup: { joinedGroupID in
                XCTAssertEqual(subgroupID, joinedGroupID)
                expectation.fulfill()
            }
        )

        // wait for `MLSService.init`'s async operations
        wait(for: [didFinishInitializationExpectation], timeout: 1)

        // WHEN
        sut.fetchAndRepairGroupIfPossible(with: groupID)

        // THEN
        // Verify expectation that the subgroup was rejoined
        wait(for: [expectation], timeout: 0.5)
    }

    func test_FetchAndRepairConversation_DoesNothingIfSubgroupIsNotOutOfSync() throws {
        // GIVEN
        let conversation = createConversation(outOfSync: true).conversation
        let groupID = try XCTUnwrap(conversation.mlsGroupID)
        let subgroupID = MLSGroupID.random()

        let subgroup = MLSSubgroup(
            cipherSuite: 0,
            epoch: 1,
            epochTimestamp: Date(),
            groupID: subgroupID,
            members: [],
            parentQualifiedID: try XCTUnwrap(conversation.qualifiedID)
        )

        let expectation = XCTestExpectation(description: "didn't rejoin subgroup")
        expectation.isInverted = true

        setMocksForConversationRepair(
            parentGroupID: groupID,
            epoch: UInt64(subgroup.epoch),
            subgroup: subgroup,
            onJoinGroup: { _ in
                expectation.fulfill()
            }
        )

        // wait for `MLSService.init`'s async operations
        wait(for: [didFinishInitializationExpectation], timeout: 1)

        // WHEN
        sut.fetchAndRepairGroupIfPossible(with: groupID)

        // THEN
        // Verify expectation that the subgroup was NOT rejoined
        wait(for: [expectation], timeout: 0.5)
    }

    private func setMocksForConversationRepair(
        parentGroupID: MLSGroupID,
        epoch: UInt64,
        subgroup: MLSSubgroup? = nil,
        onJoinGroup: @escaping (MLSGroupID) -> Void
    ) {
        // mock conversation epoch
        mockCoreCrypto.mockConversationEpoch = { _ in
            return epoch
        }

        if let subgroup = subgroup {
            // mock fetching subgroup
            mockActionsProvider.fetchSubgroupConversationIDDomainTypeContext_MockValue = subgroup
            // mock finding parent of subgroup on subconversation repository
            mockSubconversationGroupIDRepository.findSubgroupTypeAndParentIDFor_MockValue = (parentGroupID, .conference)
        } else {
            // mock conversation sync
            mockActionsProvider.syncConversationQualifiedIDContext_MockMethod = { _, _ in
                // do nothing
            }
            // mock finding parent of subgroup on subconversation repository
            mockSubconversationGroupIDRepository.findSubgroupTypeAndParentIDFor_MockValue = .some(nil)
        }

        // mock fetching group info
        mockActionsProvider.fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockValue = Data()

        // mock join group
        mockMLSActionExecutor.mockJoinGroup = { groupID, _ in
            onJoinGroup(groupID)
            return []
        }
    }

    private typealias ConversationAndOutOfSyncTuple = (conversation: ZMConversation, isOutOfSync: Bool)

    private func createConversation(outOfSync: Bool) -> ConversationAndOutOfSyncTuple {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.mlsGroupID = .random()
        conversation.remoteIdentifier = UUID()
        conversation.domain = "domain.com"
        conversation.messageProtocol = .mls
        conversation.epoch = 1

        return (conversation, outOfSync)
    }

    private func expectations(from tuples: [ConversationAndOutOfSyncTuple]) -> [MLSGroupID: XCTestExpectation] {
        tuples.reduce(into: [MLSGroupID: XCTestExpectation]()) { expectations, tuple in
            guard let groupID = tuple.conversation.mlsGroupID else {
                return
            }

            let expectation = XCTestExpectation(description: "joined group")
            expectation.isInverted = !tuple.isOutOfSync
            expectations[groupID] = expectation
        }
    }

    // MARK: - Wipe Groups

    func test_WipeGroup_IsSuccessfull() async {
        // Given
        let groupID = MLSGroupID.random()

        var count = 0
        mockCoreCrypto.mockWipeConversation = { (id: ConversationId) in
            count += 1
            XCTAssertEqual(id, groupID.bytes)
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        await sut.wipeGroup(groupID)

        // Then
        XCTAssertEqual(count, 1)
    }

    // MARK: - Key Packages

    func test_UploadKeyPackages_IsSuccessfull() async {
        // Given
        guard let clientID = await uiMOC.perform({ self.createSelfClient(onMOC: self.uiMOC).remoteIdentifier }) else {
            XCTFail("failed to get client id")
            return
        }

        let keyPackages: [[Byte]] = [
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
        mockCoreCrypto.mockClientValidKeypackagesCount = { _ in
            UInt64(unsufficientKeyPackagesAmount)
        }

        // mock keyPackages returned by core cryto
        var mockClientKeypackagesCount = 0
        mockCoreCrypto.mockClientKeypackages = { _, amountRequested in
            mockClientKeypackagesCount += 1
            XCTAssertEqual(amountRequested, UInt32(self.sut.targetUnclaimedKeyPackageCount))
            return keyPackages
        }

        // mock return value for unclaimed key packages count
        mockActionsProvider.countUnclaimedKeyPackagesClientIDContext_MockMethod = { _, _ in
            countUnclaimedKeyPackages.fulfill()
            return unsufficientKeyPackagesAmount
        }

        mockActionsProvider.uploadKeyPackagesClientIDKeyPackagesContext_MockMethod = { _, _, _ in
            uploadKeyPackages.fulfill()
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        await sut.uploadKeyPackagesIfNeeded()

        // Then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertEqual(mockClientKeypackagesCount, 1)

        let countUnclaimedKeypackagesInvocations = mockActionsProvider.countUnclaimedKeyPackagesClientIDContext_Invocations
        XCTAssertEqual(countUnclaimedKeypackagesInvocations.count, 1)
        XCTAssertEqual(countUnclaimedKeypackagesInvocations.first?.clientID, clientID)

        let uploadKeypackagesInvocations = mockActionsProvider.uploadKeyPackagesClientIDKeyPackagesContext_Invocations
        XCTAssertEqual(uploadKeypackagesInvocations.count, 1)
        XCTAssertEqual(uploadKeypackagesInvocations.first?.clientID, clientID)
        XCTAssertEqual(uploadKeypackagesInvocations.first?.keyPackages, keyPackages.map { $0.data.base64EncodedString() })
    }

    func test_UploadKeyPackages_DoesntCountUnclaimedKeyPackages_WhenNotNeeded() async {
        // Given
        await uiMOC.perform { _ = self.createSelfClient(onMOC: self.uiMOC) }

        // expectation
        let countUnclaimedKeyPackages = XCTestExpectation(description: "Count unclaimed key packages")
        countUnclaimedKeyPackages.isInverted = true

        // mock that we queried kp count recently
        userDefaultsTestSuite.test_setLastKeyPackageCountDate(Date())

        // mock that there are enough kp locally
        mockCoreCrypto.mockClientValidKeypackagesCount = { _ in
            UInt64(self.sut.targetUnclaimedKeyPackageCount)
        }

        mockActionsProvider.countUnclaimedKeyPackagesClientIDContext_MockMethod = { _, _ in
            countUnclaimedKeyPackages.fulfill()
            return 0
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        await sut.uploadKeyPackagesIfNeeded()

        // Then
        await fulfillment(of: [countUnclaimedKeyPackages], timeout: 0.5)
    }

    func test_UploadKeyPackages_DoesntUploadKeyPackages_WhenNotNeeded() async {
        // Given
        await uiMOC.perform { _ = self.createSelfClient(onMOC: self.uiMOC) }

        // we need more than half the target number to have a sufficient amount
        let unsufficientKeyPackagesAmount = sut.targetUnclaimedKeyPackageCount / 3

        // expectation
        let countUnclaimedKeyPackages = XCTestExpectation(description: "Count unclaimed key packages")
        let uploadKeyPackages = XCTestExpectation(description: "Upload key packages")
        uploadKeyPackages.isInverted = true

        // mock that we didn't query kp count recently
        userDefaultsTestSuite.test_setLastKeyPackageCountDate(.distantPast)

        // mock that we don't have enough unclaimed kp locally
        mockCoreCrypto.mockClientValidKeypackagesCount = { _ in
            return UInt64(unsufficientKeyPackagesAmount)
        }

        // mock return value for unclaimed key packages count
        mockActionsProvider.countUnclaimedKeyPackagesClientIDContext_MockMethod = { _, _ in
            countUnclaimedKeyPackages.fulfill()
            return self.sut.targetUnclaimedKeyPackageCount
        }

        mockActionsProvider.uploadKeyPackagesClientIDKeyPackagesContext_MockMethod = { _, _, _ in
            uploadKeyPackages.fulfill()
        }

        mockCoreCrypto.mockClientKeypackages = { _, _ in
            XCTFail("shouldn't be generating key packages")
            return []
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        await sut.uploadKeyPackagesIfNeeded()

        // Then
        await fulfillment(of: [countUnclaimedKeyPackages, uploadKeyPackages], timeout: 0.5)
    }

    // MARK: - Welcome message

    func test_ProcessWelcomeMessage_Sucess() async throws {
        // Given
        let groupID = MLSGroupID.random()
        let message = Data.random().base64EncodedString()

        // Mock
        mockCoreCrypto.mockProcessWelcomeMessage = { _, _ in
            groupID.bytes
        }

        var mockClientValidKeypackagesCountCount = 0
        mockCoreCrypto.mockClientValidKeypackagesCount = { _ in
            mockClientValidKeypackagesCountCount += 1
            return UInt64(self.sut.targetUnclaimedKeyPackageCount)
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        _ = try await sut.processWelcomeMessage(welcomeMessage: message)

        // Then
        XCTAssertEqual(mockClientValidKeypackagesCountCount, 1)
        XCTAssertEqual(mockStaleMLSKeyDetector.calls.keyingMaterialUpdated, [groupID])
    }

    // MARK: - Update key material

    func test_UpdateKeyMaterial_WhenInitializing() throws {
        // Given
        let group1 = MLSGroupID.random()
        let group2 = MLSGroupID.random()

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in
            throw MLSActionExecutor.Error.noPendingProposals
        }

        // Mock stale groups.
        mockStaleMLSKeyDetector.groupsWithStaleKeyingMaterial = [group1, group2]

        // Mock updating key material.
        var mockUpdateKeyingMaterialArguments = Set<MLSGroupID>()
        mockMLSActionExecutor.mockUpdateKeyMaterial = {
            mockUpdateKeyingMaterialArguments.insert($0)
            return []
        }

        // Expectations
        keyMaterialUpdatedExpectation = self.expectation(description: "did update key material")
        didFinishInitializationExpectation = expectation(description: "did finish initialization")

        // When
        let sut = MLSService(
            context: uiMOC,
            coreCrypto: mockSafeCoreCrypto,
            mlsActionExecutor: mockMLSActionExecutor,
            conversationEventProcessor: mockConversationEventProcessor,
            staleKeyMaterialDetector: mockStaleMLSKeyDetector,
            userDefaults: userDefaultsTestSuite,
            actionsProvider: mockActionsProvider,
            delegate: self,
            syncStatus: mockSyncStatus
        )

        // Then
        _ = waitForCustomExpectations(withTimeout: 5)

        // Then we updated the key material.
        XCTAssertEqual(
            mockUpdateKeyingMaterialArguments,
            [group1, group2]
        )

        // Then we informed the detector.
        XCTAssertEqual(
            Set(mockStaleMLSKeyDetector.calls.keyingMaterialUpdated),
            Set([group1, group2])
        )

        // Then we didn't process any events.
        XCTAssertEqual(
            mockConversationEventProcessor.processConversationEvents_Invocations.flatMap(\.self),
            []
        )

        // Then we updated the last check date.
        XCTAssertEqual(
            sut.lastKeyMaterialUpdateCheck.timeIntervalSinceNow,
            Date().timeIntervalSinceNow,
            accuracy: 0.1
        )

        // Then we scheduled a timer.
        let timer = try XCTUnwrap(sut.keyMaterialUpdateCheckTimer)
        XCTAssertTrue(timer.isValid)

        XCTAssertEqual(
            timer.fireDate.timeIntervalSinceNow,
            Date().addingTimeInterval(.oneDay).timeIntervalSinceNow,
            accuracy: 0.1
        )
    }

    func test_SendPendingProposal_BeforeUpdatingKeyMaterial_WhenInitializing() throws {
        // Given
        let futureCommitDate = Date().addingTimeInterval(2)
        let groupID = MLSGroupID.random()
        var conversation: ZMConversation!

        uiMOC.performAndWait {
            // A group with pending proposal in the future.
            conversation = createConversation(in: uiMOC)
            conversation.mlsGroupID = groupID
            conversation.commitPendingProposalDate = futureCommitDate
        }

        // Expectation
        keyMaterialUpdatedExpectation = expectation(description: "did update key material")
        didFinishInitializationExpectation = expectation(description: "did finish initialization")

        // Mock committing pending proposal.
        var mockCommitPendingProposalsArguments = [MLSGroupID]()
        let updateEvent = dummyMemberJoinEvent()

        mockMLSActionExecutor.mockCommitPendingProposals = {
            mockCommitPendingProposalsArguments.append($0)
            return [updateEvent]
        }

        // Mock stale groups.
        mockStaleMLSKeyDetector.groupsWithStaleKeyingMaterial = [groupID]

        // Mock updating key material.
        var mockUpdateKeyingMaterialArguments = Set<MLSGroupID>()
        mockMLSActionExecutor.mockUpdateKeyMaterial = {
            mockUpdateKeyingMaterialArguments.insert($0)
            return []
        }

        // When
        let sut = MLSService(
            context: uiMOC,
            coreCrypto: mockSafeCoreCrypto,
            mlsActionExecutor: mockMLSActionExecutor,
            conversationEventProcessor: mockConversationEventProcessor,
            staleKeyMaterialDetector: mockStaleMLSKeyDetector,
            userDefaults: userDefaultsTestSuite,
            actionsProvider: mockActionsProvider,
            delegate: self,
            syncStatus: mockSyncStatus
        )

        // Then
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 5))

        // Then we committed the pending proposal.
        XCTAssertEqual(mockCommitPendingProposalsArguments, [groupID])

        // Then the conversation has been updated.
        uiMOC.performAndWait {
            XCTAssertNil(conversation.commitPendingProposalDate)
        }

        // Then we updated the key material.
        XCTAssertEqual(
            mockUpdateKeyingMaterialArguments,
            [groupID]
        )

        // Then we informed the key detector of the update.
        XCTAssertEqual(
            Set(mockStaleMLSKeyDetector.calls.keyingMaterialUpdated),
            Set([groupID])
        )

        // Then we processed the update event from the proposal.
        XCTAssertEqual(
            mockConversationEventProcessor.processConversationEvents_Invocations,
            [[updateEvent], []]
        )

        // Then we updated the last check date.
        XCTAssertEqual(
            sut.lastKeyMaterialUpdateCheck.timeIntervalSinceNow,
            Date().timeIntervalSinceNow,
            accuracy: 3
        )

        // Then we scheduled a timer.
        let timer = try XCTUnwrap(sut.keyMaterialUpdateCheckTimer)
        XCTAssertTrue(timer.isValid)

        XCTAssertEqual(
            timer.fireDate.timeIntervalSinceNow,
            Date().addingTimeInterval(.oneDay).timeIntervalSinceNow,
            accuracy: 3
        )
    }

    // MARK: - Rety on commit failure

    // Note: these tests are asserting the behavior of the retry mechanism only, which
    // is used in various operations, such as adding members or removing clients. For
    // these tests, we will just pick one operation.

    func test_RetryOnCommitFailure_SingleRetry() async throws {
        // Given a group.
        let groupID = MLSGroupID.random()

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in
            throw MLSActionExecutor.Error.noPendingProposals
        }

        // Mock one failure to update key material, then a success.
        var mockUpdateKeyMaterialCount = 0
        mockMLSActionExecutor.mockUpdateKeyMaterial = { _ in
            defer { mockUpdateKeyMaterialCount += 1 }
            switch mockUpdateKeyMaterialCount {
            case 0:
                throw MLSActionExecutor.Error.failedToSendCommit(recovery: .retryAfterQuickSync)
            default:
                return []
            }
        }

        // Mock quick sync.
        var mockPerformQuickSyncCount = 0
        mockSyncStatus.mockPerformQuickSync = {
            mockPerformQuickSyncCount += 1
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        try await sut.updateKeyMaterial(for: groupID)

        // Then it attempted to update key material twice.
        XCTAssertEqual(mockUpdateKeyMaterialCount, 2)

        // Then it performed a quick sync once.
        XCTAssertEqual(mockPerformQuickSyncCount, 1)

        // Then processed the result once.
        XCTAssertEqual(mockConversationEventProcessor.processConversationEvents_Invocations, [[]])
    }

    func test_RetryOnCommitFailure_MultipleRetries() async throws {
        // Given a group.
        let groupID = MLSGroupID.random()

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in
            throw MLSActionExecutor.Error.noPendingProposals
        }

        // Mock three failures to update key material, then a success.
        var mockUpdateKeyMaterialCount = 0
        mockMLSActionExecutor.mockUpdateKeyMaterial = { _ in
            defer { mockUpdateKeyMaterialCount += 1 }
            switch mockUpdateKeyMaterialCount {
            case 0..<3:
                throw MLSActionExecutor.Error.failedToSendCommit(recovery: .retryAfterQuickSync)
            default:
                return []
            }
        }

        // Mock quick sync.
        var mockPerformQuickSyncCount = 0
        mockSyncStatus.mockPerformQuickSync = {
            mockPerformQuickSyncCount += 1
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        try await sut.updateKeyMaterial(for: groupID)

        // Then it attempted to update key material 4 times (3 failed, 1 success).
        XCTAssertEqual(mockUpdateKeyMaterialCount, 4)

        // Then it performed a quick sync 3 times (for 3 failures).
        XCTAssertEqual(mockPerformQuickSyncCount, 3)

        // Then processed the result once.
        XCTAssertEqual(mockConversationEventProcessor.processConversationEvents_Invocations, [[]])
    }

    func test_RetryOnCommitFailure_ChainMultipleRecoverableOperations() async throws {
        // Given a group.
        let groupID = MLSGroupID.random()

        // Mock two failures to commit pending proposals, then a success.
        var mockCommitPendingProposalsCount = 0
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in
            defer { mockCommitPendingProposalsCount += 1 }
            switch mockCommitPendingProposalsCount {
            case 0..<2:
                throw MLSActionExecutor.Error.failedToSendCommit(recovery: .retryAfterQuickSync)
            default:
                return []
            }
        }

        // Mock three failures to update key material, then a success.
        var mockUpdateKeyMaterialCount = 0
        mockMLSActionExecutor.mockUpdateKeyMaterial = { _ in
            defer { mockUpdateKeyMaterialCount += 1 }
            switch mockUpdateKeyMaterialCount {
            case 0..<3:
                throw MLSActionExecutor.Error.failedToSendCommit(recovery: .retryAfterQuickSync)
            default:
                return []
            }
        }

        // Mock quick sync.
        var mockPerformQuickSyncCount = 0
        mockSyncStatus.mockPerformQuickSync = {
            mockPerformQuickSyncCount += 1
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        try await sut.updateKeyMaterial(for: groupID)

        // Then it attempted to commit pending proposals 3 times (2 failed, 1 success).
        XCTAssertEqual(mockCommitPendingProposalsCount, 3)

        // Then it attempted to update key material 4 times (3 failed, 1 success).
        XCTAssertEqual(mockUpdateKeyMaterialCount, 4)

        // Then it performed a quick sync 5 times (for 2 + 3 failures).
        XCTAssertEqual(mockPerformQuickSyncCount, 5)

        // Then processed the results twice (1 for each success).
        XCTAssertEqual(mockConversationEventProcessor.processConversationEvents_Invocations, [[], []])
    }

    func test_RetryOnCommitFailure_CommitPendingProposalsAfterRetry() async throws {
        // Given a group.
        let groupID = MLSGroupID.random()

        // Mock no pending proposals when first trying to update key material, but
        // then a successful pending proposal commit after the failed commit is migrated
        // by Core Crypto.
        var mockCommitPendingProposalsCount = 0
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in
            defer { mockCommitPendingProposalsCount += 1 }
            switch mockCommitPendingProposalsCount {
            case 0:
                throw MLSActionExecutor.Error.noPendingProposals
            default:
                return []
            }
        }

        // Mock failures to update key material: but no success since the commit was
        // migrated to a pending proposal.
        var mockUpdateKeyMaterialCount = 0
        mockMLSActionExecutor.mockUpdateKeyMaterial = { _ in
            defer { mockUpdateKeyMaterialCount += 1 }
            throw MLSActionExecutor.Error.failedToSendCommit(recovery: .commitPendingProposalsAfterQuickSync)
        }

        // Mock quick sync.
        var mockPerformQuickSyncCount = 0
        mockSyncStatus.mockPerformQuickSync = {
            mockPerformQuickSyncCount += 1
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        try await sut.updateKeyMaterial(for: groupID)

        // Then it attempted to commit pending proposals twice (1 no-op, 1 success).
        XCTAssertEqual(mockCommitPendingProposalsCount, 2)

        // Then it attempted to update key material once.
        XCTAssertEqual(mockUpdateKeyMaterialCount, 1)

        // Then it performed a quick sync once.
        XCTAssertEqual(mockPerformQuickSyncCount, 1)

        // Then processed the result once.
        XCTAssertEqual(mockConversationEventProcessor.processConversationEvents_Invocations, [[]])
    }

    func test_RetryOnCommitFailure_ItGivesUp() async throws {
        // Given a group.
        let groupID = MLSGroupID.random()

        // Mock no pending proposals.
        mockMLSActionExecutor.mockCommitPendingProposals = { _ in
            throw MLSActionExecutor.Error.noPendingProposals
        }

        // Mock failures to update key material, no successes.
        var mockUpdateKeyMaterialCount = 0
        mockMLSActionExecutor.mockUpdateKeyMaterial = { _ in
            defer { mockUpdateKeyMaterialCount += 1 }
            throw MLSActionExecutor.Error.failedToSendCommit(recovery: .giveUp)
        }

        // Mock quick sync.
        var mockPerformQuickSyncCount = 0
        mockSyncStatus.mockPerformQuickSync = {
            mockPerformQuickSyncCount += 1
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // Then
        await assertItThrows(error: MLSActionExecutor.Error.failedToSendCommit(recovery: .giveUp)) {
            // When
            try await sut.updateKeyMaterial(for: groupID)
        }

        // Then it attempted to update key material once.
        XCTAssertEqual(mockUpdateKeyMaterialCount, 1)

        // Then it didn't perform a quick sync.
        XCTAssertEqual(mockPerformQuickSyncCount, 0)

        // Then it didn't process any result.
        XCTAssertEqual(mockConversationEventProcessor.processConversationEvents_Invocations, [])
    }

    // MARK: - Subgroups

    func test_CreateOrJoinSubgroup_CreateNewGroup() async throws {
        // Given
        let parentQualifiedID = QualifiedID.random()
        let parentID = MLSGroupID.random()
        let subgroupID = MLSGroupID.random()
        let epoch = 0
        let epochTimestamp = Date()

        mockActionsProvider.fetchSubgroupConversationIDDomainTypeContext_MockMethod = { _, _, _, _ in
            return MLSSubgroup(
                cipherSuite: 0,
                epoch: epoch,
                epochTimestamp: epochTimestamp,
                groupID: subgroupID,
                members: [],
                parentQualifiedID: parentQualifiedID
            )
        }

        mockCoreCrypto.mockCreateConversation = { groupID, _, _ in
            XCTAssertEqual(groupID, subgroupID.bytes)
        }

        mockMLSActionExecutor.mockCommitPendingProposals = { groupID in
            XCTAssertEqual(groupID, subgroupID)
            return []
        }

        mockMLSActionExecutor.mockUpdateKeyMaterial = { groupID in
            XCTAssertEqual(groupID, subgroupID)
            return []
        }

        mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_MockMethod = { _, _, _ in
            // no op
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        let result = try await sut.createOrJoinSubgroup(
            parentQualifiedID: parentQualifiedID,
            parentID: parentID
        )

        // Then
        XCTAssertEqual(result, subgroupID)

        XCTAssertEqual(mockActionsProvider.fetchSubgroupConversationIDDomainTypeContext_Invocations.count, 1)
        let fetchSubroupInvocation = try XCTUnwrap(mockActionsProvider.fetchSubgroupConversationIDDomainTypeContext_Invocations.first)
        XCTAssertEqual(fetchSubroupInvocation.conversationID, parentQualifiedID.uuid)
        XCTAssertEqual(fetchSubroupInvocation.domain, parentQualifiedID.domain)
        XCTAssertEqual(fetchSubroupInvocation.type, .conference)

        XCTAssertEqual(mockCoreCrypto.mockCreateConversationCount, 1)
        XCTAssertEqual(mockMLSActionExecutor.commitPendingProposalsCount, 1)
        XCTAssertEqual(mockMLSActionExecutor.updateKeyMaterialCount, 1)

        XCTAssertEqual(
            mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_Invocations.count,
            1
        )
        let subconversationGroupID = try XCTUnwrap(mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_Invocations.element(atIndex: 0))
        XCTAssertEqual(subconversationGroupID.groupID, subgroupID)
        XCTAssertEqual(subconversationGroupID.type, .conference)
        XCTAssertEqual(subconversationGroupID.parentGroupID, parentID)
    }

    func test_CreateOrJoinSubgroup_DeleteOldGroupCreateNewGroup() async throws {
        // Given
        let parentQualifiedID = QualifiedID.random()
        let parentID = MLSGroupID.random()
        let subgroupID = MLSGroupID.random()
        let epoch = 1
        let epochTimestamp = Date(timeIntervalSinceNow: -.oneDay)

        mockActionsProvider.deleteSubgroupConversationIDDomainSubgroupTypeContext_MockMethod = { _, _, _, _ in
            // no-op
        }

        mockActionsProvider.fetchSubgroupConversationIDDomainTypeContext_MockMethod = { _, _, _, _ in
            return MLSSubgroup(
                cipherSuite: 0,
                epoch: epoch,
                epochTimestamp: epochTimestamp,
                groupID: subgroupID,
                members: [],
                parentQualifiedID: parentQualifiedID
            )
        }

        mockCoreCrypto.mockCreateConversation = { groupID, _, _ in
            XCTAssertEqual(groupID, subgroupID.bytes)
        }

        mockMLSActionExecutor.mockCommitPendingProposals = { groupID in
            XCTAssertEqual(groupID, subgroupID)
            return []
        }

        mockMLSActionExecutor.mockUpdateKeyMaterial = { groupID in
            XCTAssertEqual(groupID, subgroupID)
            return []
        }

        mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_MockMethod = { _, _, _ in
            // no op
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        let result = try await sut.createOrJoinSubgroup(
            parentQualifiedID: parentQualifiedID,
            parentID: parentID
        )

        // Then
        XCTAssertEqual(result, subgroupID)

        XCTAssertEqual(mockActionsProvider.deleteSubgroupConversationIDDomainSubgroupTypeContext_Invocations.count, 1)
        let deleteSubroupInvocation = try XCTUnwrap(mockActionsProvider.deleteSubgroupConversationIDDomainSubgroupTypeContext_Invocations.first)
        XCTAssertEqual(deleteSubroupInvocation.conversationID, parentQualifiedID.uuid)
        XCTAssertEqual(deleteSubroupInvocation.domain, parentQualifiedID.domain)
        XCTAssertEqual(deleteSubroupInvocation.subgroupType, .conference)

        XCTAssertEqual(mockActionsProvider.fetchSubgroupConversationIDDomainTypeContext_Invocations.count, 1)
        let fetchSubroupInvocation = try XCTUnwrap(mockActionsProvider.fetchSubgroupConversationIDDomainTypeContext_Invocations.first)
        XCTAssertEqual(fetchSubroupInvocation.conversationID, parentQualifiedID.uuid)
        XCTAssertEqual(fetchSubroupInvocation.domain, parentQualifiedID.domain)
        XCTAssertEqual(fetchSubroupInvocation.type, .conference)

        XCTAssertEqual(mockCoreCrypto.mockCreateConversationCount, 1)
        XCTAssertEqual(mockMLSActionExecutor.commitPendingProposalsCount, 1)
        XCTAssertEqual(mockMLSActionExecutor.updateKeyMaterialCount, 1)

        XCTAssertEqual(
            mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_Invocations.count,
            1
        )
        let subconversationGroupID = try XCTUnwrap(mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_Invocations.element(atIndex: 0))
        XCTAssertEqual(subconversationGroupID.groupID, subgroupID)
        XCTAssertEqual(subconversationGroupID.type, .conference)
        XCTAssertEqual(subconversationGroupID.parentGroupID, parentID)
    }

    func test_CreateOrJoinSubgroup_JoinExistingGroup() async throws {
        // Given
        let parentQualifiedID = QualifiedID.random()
        let parentID = MLSGroupID.random()
        let subgroupID = MLSGroupID.random()
        let epoch = 1
        let epochTimestamp = Date()
        let publicGroupState = Data.random()

        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = parentQualifiedID.uuid
        conversation.domain = parentQualifiedID.domain
        conversation.mlsGroupID = parentID

        mockActionsProvider.fetchSubgroupConversationIDDomainTypeContext_MockMethod = { _, _, _, _ in
            return MLSSubgroup(
                cipherSuite: 0,
                epoch: epoch,
                epochTimestamp: epochTimestamp,
                groupID: subgroupID,
                members: [],
                parentQualifiedID: parentQualifiedID
            )
        }

        mockActionsProvider.fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockValue = publicGroupState

        mockMLSActionExecutor.mockJoinGroup = {
            XCTAssertEqual($0, subgroupID)
            XCTAssertEqual($1, publicGroupState)
            return []
        }

        mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_MockMethod = { _, _, _ in
            // no op
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        let result = try await sut.createOrJoinSubgroup(
            parentQualifiedID: parentQualifiedID,
            parentID: parentID
        )

        // Then
        XCTAssertEqual(result, subgroupID)

        XCTAssertEqual(mockActionsProvider.fetchSubgroupConversationIDDomainTypeContext_Invocations.count, 1)
        let fetchSubroupInvocation = try XCTUnwrap(mockActionsProvider.fetchSubgroupConversationIDDomainTypeContext_Invocations.first)
        XCTAssertEqual(fetchSubroupInvocation.conversationID, parentQualifiedID.uuid)
        XCTAssertEqual(fetchSubroupInvocation.domain, parentQualifiedID.domain)
        XCTAssertEqual(fetchSubroupInvocation.type, .conference)

        XCTAssertEqual(mockActionsProvider.fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_Invocations.count, 1)
        let fetchGroupInfoInvocation = try XCTUnwrap(mockActionsProvider.fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_Invocations.first)
        XCTAssertEqual(fetchGroupInfoInvocation.conversationId, parentQualifiedID.uuid)
        XCTAssertEqual(fetchGroupInfoInvocation.domain, parentQualifiedID.domain)
        XCTAssertEqual(fetchGroupInfoInvocation.subgroupType, .conference)

        XCTAssertEqual(mockMLSActionExecutor.mockJoinGroupCount, 1)

        XCTAssertEqual(
            mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_Invocations.count,
            1
        )
        let subconversationGroupID = try XCTUnwrap(mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_Invocations.element(atIndex: 0))
        XCTAssertEqual(subconversationGroupID.groupID, subgroupID)
        XCTAssertEqual(subconversationGroupID.type, .conference)
        XCTAssertEqual(subconversationGroupID.parentGroupID, parentID)
    }

    func test_LeaveSubconversation() async throws {
        // Given
        let parentID = QualifiedID.random()
        let parentGroupID = MLSGroupID.random()
        let subconversationGroupID = MLSGroupID.random()
        let subconversationType = SubgroupType.conference

        mockActionsProvider.leaveSubconversationConversationIDDomainSubconversationTypeContext_MockMethod = { _, _, _, _ in
            // no op
        }

        var mockWipeConversationArguments = [[Byte]]()
        mockCoreCrypto.mockWipeConversation = {
            mockWipeConversationArguments.append($0)
        }

        mockSubconversationGroupIDRepository.fetchSubconversationGroupIDForTypeParentGroupID_MockValue = subconversationGroupID

        mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_MockMethod = { _, _, _ in
            // no op
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        try await sut.leaveSubconversation(
            parentQualifiedID: parentID,
            parentGroupID: parentGroupID,
            subconversationType: subconversationType
        )

        // Then
        let leaveSubconversationInvocations = mockActionsProvider.leaveSubconversationConversationIDDomainSubconversationTypeContext_Invocations
        XCTAssertEqual(leaveSubconversationInvocations.count, 1)
        let leaveSubconversationInvocation = try XCTUnwrap(leaveSubconversationInvocations.first)
        XCTAssertEqual(leaveSubconversationInvocation.conversationID, parentID.uuid)
        XCTAssertEqual(leaveSubconversationInvocation.domain, parentID.domain)
        XCTAssertEqual(leaveSubconversationInvocation.subconversationType, subconversationType)

        XCTAssertEqual(mockWipeConversationArguments, [subconversationGroupID.bytes])

        let clearSubconversationGroupIDInvocations = mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_Invocations
        XCTAssertEqual(clearSubconversationGroupIDInvocations.count, 1)
        let clearSubconversationGroupIDInvocation = try XCTUnwrap(clearSubconversationGroupIDInvocations.first)
        XCTAssertEqual(clearSubconversationGroupIDInvocation.groupID, nil)
        XCTAssertEqual(clearSubconversationGroupIDInvocation.type, .conference)
        XCTAssertEqual(clearSubconversationGroupIDInvocation.parentGroupID, parentGroupID)
    }

    func test_LeaveSubconversationIfNeeded_GroupIDExists() async throws {
        // Given
        let parentID = QualifiedID.random()
        let parentGroupID = MLSGroupID.random()
        let subconversationGroupID = MLSGroupID.random()
        let subconversationType = SubgroupType.conference
        let selfClientID = MLSClientID.random()

        mockSubconversationGroupIDRepository.fetchSubconversationGroupIDForTypeParentGroupID_MockValue = subconversationGroupID
        mockCoreCrypto.mockConversationExists = {
            XCTAssertEqual($0, subconversationGroupID.bytes)
            return true
        }

        mockActionsProvider.leaveSubconversationConversationIDDomainSubconversationTypeContext_MockMethod = { _, _, _, _ in
            // no op
        }

        var mockWipeConversationArguments = [[Byte]]()
        mockCoreCrypto.mockWipeConversation = {
            mockWipeConversationArguments.append($0)
        }

        mockSubconversationGroupIDRepository.fetchSubconversationGroupIDForTypeParentGroupID_MockValue = subconversationGroupID

        mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_MockMethod = { _, _, _ in
            // no op
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        try await sut.leaveSubconversationIfNeeded(
            parentQualifiedID: parentID,
            parentGroupID: parentGroupID,
            subconversationType: subconversationType,
            selfClientID: selfClientID
        )

        // Then
        let invocations = mockActionsProvider.leaveSubconversationConversationIDDomainSubconversationTypeContext_Invocations
        XCTAssertEqual(invocations.count, 1)
        let invocation = try XCTUnwrap(invocations.element(atIndex: 0))
        XCTAssertEqual(invocation.conversationID, parentID.uuid)
        XCTAssertEqual(invocation.domain, parentID.domain)
        XCTAssertEqual(invocation.subconversationType, subconversationType)

        XCTAssertEqual(mockWipeConversationArguments, [subconversationGroupID.bytes])

        let clearSubconversationGroupIDInvocations = mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_Invocations
        XCTAssertEqual(clearSubconversationGroupIDInvocations.count, 1)
        let clearSubconversationGroupIDInvocation = try XCTUnwrap(clearSubconversationGroupIDInvocations.first)
        XCTAssertEqual(clearSubconversationGroupIDInvocation.groupID, nil)
        XCTAssertEqual(clearSubconversationGroupIDInvocation.type, .conference)
        XCTAssertEqual(clearSubconversationGroupIDInvocation.parentGroupID, parentGroupID)
    }

    func test_LeaveSubconversationIfNeeded_GroupIDDoesNotExist() async throws {
        // Given
        let parentID = QualifiedID.random()
        let parentGroupID = MLSGroupID.random()
        let subconversationGroupID = MLSGroupID.random()
        let subconversationType = SubgroupType.conference
        let selfClientID = MLSClientID.random()

        mockSubconversationGroupIDRepository.fetchSubconversationGroupIDForTypeParentGroupID_MockMethod = { _, _ in
            return nil
        }

        mockActionsProvider.fetchSubgroupConversationIDDomainTypeContext_MockMethod = { _, _, _, _ in
            return MLSSubgroup(
                cipherSuite: 1,
                epoch: 1,
                epochTimestamp: nil,
                groupID: subconversationGroupID,
                members: [selfClientID],
                parentQualifiedID: parentID
            )
        }

        mockActionsProvider.leaveSubconversationConversationIDDomainSubconversationTypeContext_MockMethod = { _, _, _, _ in
            // no op
        }

        var mockWipeConversationArguments = [[Byte]]()
        mockCoreCrypto.mockWipeConversation = {
            mockWipeConversationArguments.append($0)
        }

        mockSubconversationGroupIDRepository.fetchSubconversationGroupIDForTypeParentGroupID_MockValue = subconversationGroupID

        mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_MockMethod = { _, _, _ in
            // no op
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        try await sut.leaveSubconversationIfNeeded(
            parentQualifiedID: parentID,
            parentGroupID: parentGroupID,
            subconversationType: subconversationType,
            selfClientID: selfClientID
        )

        // Then
        let invocations = mockActionsProvider.leaveSubconversationConversationIDDomainSubconversationTypeContext_Invocations
        XCTAssertEqual(invocations.count, 1)
        let invocation = try XCTUnwrap(invocations.element(atIndex: 0))
        XCTAssertEqual(invocation.conversationID, parentID.uuid)
        XCTAssertEqual(invocation.domain, parentID.domain)
        XCTAssertEqual(invocation.subconversationType, subconversationType)

        XCTAssertEqual(mockWipeConversationArguments, [subconversationGroupID.bytes])

        let clearSubconversationGroupIDInvocations = mockSubconversationGroupIDRepository.storeSubconversationGroupIDForTypeParentGroupID_Invocations
        XCTAssertEqual(clearSubconversationGroupIDInvocations.count, 1)
        let clearSubconversationGroupIDInvocation = try XCTUnwrap(clearSubconversationGroupIDInvocations.first)
        XCTAssertEqual(clearSubconversationGroupIDInvocation.groupID, nil)
        XCTAssertEqual(clearSubconversationGroupIDInvocation.type, .conference)
        XCTAssertEqual(clearSubconversationGroupIDInvocation.parentGroupID, parentGroupID)
    }

    // MARK: - On conference info changed

    func test_OnEpochChanged_InterleavesSources() throws {
        // Given
        let groupID1 = MLSGroupID.random()
        let groupID2 = MLSGroupID.random()
        let groupID3 = MLSGroupID.random()

        // Mock epoch changes
        let epochChangedFromDecryptionSerivce = PassthroughSubject<MLSGroupID, Never>()
        mockDecryptionService.onEpochChanged_MockValue = epochChangedFromDecryptionSerivce.eraseToAnyPublisher()

        let epochChangedFromActionExecutor = PassthroughSubject<MLSGroupID, Never>()
        mockMLSActionExecutor.mockOnEpochChanged = epochChangedFromActionExecutor.eraseToAnyPublisher

        // Colect ids for groups with changed epochs
        var receivedGroupIDs = [MLSGroupID]()
        let didReceiveGroupIDs = expectation(description: "didReceiveGroupIDs")
        let cancellable = sut.onEpochChanged().collect(3).sink {
            receivedGroupIDs = $0
            didReceiveGroupIDs.fulfill()
        }

        // wait for `MLSService.init`'s async operations
        wait(for: [didFinishInitializationExpectation], timeout: 1)

        // When
        epochChangedFromDecryptionSerivce.send(groupID1)
        epochChangedFromActionExecutor.send(groupID2)
        epochChangedFromDecryptionSerivce.send(groupID3)

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        cancellable.cancel()
        XCTAssertEqual(receivedGroupIDs, [groupID1, groupID2, groupID3])
    }

    func test_OnConferenceInfoChanged_WhenEpochChangesForParentConversation() async throws {
        // Given
        let parentGroupID = MLSGroupID.random()
        let subconversationGroupID = MLSGroupID.random()

        // When then
        try await assertConferenceInfoIsReceivedWhenEpochChanges(
            parentGroupID: parentGroupID,
            subconversationGroupID: subconversationGroupID,
            epochChangeSequence: .random(), .random(), parentGroupID
        )
    }

    func test_OnConferenceInfoChanged_WhenEpochChangesForSubconversation() async throws {
        // Given
        let parentGroupID = MLSGroupID.random()
        let subconversationGroupID = MLSGroupID.random()

        // When then
        try await assertConferenceInfoIsReceivedWhenEpochChanges(
            parentGroupID: parentGroupID,
            subconversationGroupID: subconversationGroupID,
            epochChangeSequence: .random(), .random(), subconversationGroupID
        )
    }

    private func assertConferenceInfoIsReceivedWhenEpochChanges(
        parentGroupID: MLSGroupID,
        subconversationGroupID: MLSGroupID,
        epochChangeSequence: MLSGroupID...
    ) async throws {
        // Mock epoch changes
        let epochChangedFromDecryptionSerivce = PassthroughSubject<MLSGroupID, Never>()
        mockDecryptionService.onEpochChanged_MockValue = epochChangedFromDecryptionSerivce.eraseToAnyPublisher()

        let epochChangedFromActionExecutor = PassthroughSubject<MLSGroupID, Never>()
        mockMLSActionExecutor.mockOnEpochChanged = epochChangedFromActionExecutor.eraseToAnyPublisher

        // Mock conference info
        let epoch: UInt64 = 42
        let key = Data.random(byteCount: 32)
        let clientID = MLSClientID.random()
        let clientIDBytes = try XCTUnwrap(clientID.rawValue.utf8Data?.bytes)

        mockCoreCrypto.mockConversationEpoch = { groupID in
            XCTAssertEqual(groupID, subconversationGroupID.bytes)
            return epoch
        }

        mockCoreCrypto.mockExportSecretKey = { groupID, _ in
            XCTAssertEqual(groupID, subconversationGroupID.bytes)
            return key.bytes
        }

        mockCoreCrypto.mockGetClientIds = { groupID in
            XCTAssertTrue(groupID.isOne(of: parentGroupID.bytes, subconversationGroupID.bytes))
            return [clientIDBytes]
        }

        // Collect the received conference infos
        let conferenceInfoChanges = sut.onConferenceInfoChange(
            parentGroupID: parentGroupID,
            subConversationGroupID: subconversationGroupID
        )

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        for groupID in epochChangeSequence {
            epochChangedFromDecryptionSerivce.send(groupID)
        }

        // Then
        let receivedConferenceInfo = try await conferenceInfoChanges.first(where: { _ in true })
        let expectedConferenceInfo = MLSConferenceInfo(
            epoch: epoch,
            keyData: key,
            members: [.init(id: clientID, isInSubconversation: true)]
        )

        XCTAssertEqual(receivedConferenceInfo, expectedConferenceInfo)
    }

    // MARK: - Self group

    func test_itCreatesSelfGroup_WithNoKeyPackages_Successfully() async throws {
        BackendInfo.domain = "example.com"

        // Given a group.
        let groupID = MLSGroupID.random()
        let expectation1 = self.expectation(description: "CreateConversation should be called")
        let expectation2 = self.expectation(description: "UpdateKeyMaterial should be called")

        mockCoreCrypto.mockCreateConversation = { _, _, _ in
            expectation1.fulfill()
        }

        mockMLSActionExecutor.mockCommitPendingProposals = { _ in
            return []
        }

        mockActionsProvider.claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_MockValue = []

        var mockUpdateKeyingMaterialArguments = [MLSGroupID]()
        mockMLSActionExecutor.mockUpdateKeyMaterial = {
            defer { expectation2.fulfill() }
            mockUpdateKeyingMaterialArguments.append($0)
            return []
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // WHEN
        await sut.createSelfGroup(for: groupID)

        // THEN
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
        XCTAssertEqual(mockUpdateKeyingMaterialArguments, [groupID])
    }

    func test_itCreatesSelfGroup_WithKeyPackages_Successfully() async throws {
        BackendInfo.domain = "example.com"

        // Given a group.
        let expectation1 = self.expectation(description: "CreateConversation should be called")
        let expectation2 = self.expectation(description: "AddMembers should be called")
        mockCoreCrypto.mockCreateConversation = { _, _, _ in
            expectation1.fulfill()
        }

        mockActionsProvider.claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_MockMethod = { _, _, _, _ in
            return [KeyPackage.init(client: "", domain: "", keyPackage: "", keyPackageRef: "", userID: UUID())]
        }

        mockMLSActionExecutor.mockCommitPendingProposals = { _ in
            return [ZMUpdateEvent()]
        }

        mockMLSActionExecutor.mockAddMembers = { _, _ in
            expectation2.fulfill()
            return [ZMUpdateEvent()]
        }

        let groupID = MLSGroupID.random()

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // WHEN
        await sut.createSelfGroup(for: groupID)

        // THEN
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 2.0))
    }

    func test_GenerateNewEpoch() async throws {
        // Given
        let groupID = MLSGroupID.random()

        var commitPendingProposalsInvocations = [MLSGroupID]()
        mockMLSActionExecutor.mockCommitPendingProposals = {
            commitPendingProposalsInvocations.append($0)
            return []
        }

        var updateKeyMaterialInvocations = [MLSGroupID]()
        mockMLSActionExecutor.mockUpdateKeyMaterial = {
            updateKeyMaterialInvocations.append($0)
            return []
        }

        // wait for `MLSService.init`'s async operations
        await fulfillment(of: [didFinishInitializationExpectation], timeout: 1)

        // When
        try await sut.generateNewEpoch(groupID: groupID)

        // Then
        XCTAssertEqual(commitPendingProposalsInvocations, [groupID])
        XCTAssertEqual(updateKeyMaterialInvocations, [groupID])
    }

    // MARK: - Guest links

    func test_ItJoinsNewGroupForGuestLinkWhenConversationDoesNotExist() async throws {
        // Given
        let groupID = MLSGroupID.random()
        var conversation: ZMConversation!

        await uiMOC.perform { [self] in
            // A group with pending proposal in the future
            conversation = createConversation(in: uiMOC)
            conversation.mlsGroupID = groupID
            conversation.messageProtocol = .mls
            conversation.domain = "example.com"
        }

        let expectation1 = self.expectation(description: "CreateConversation should be called")

        mockMLSActionExecutor.mockJoinGroup = { _, _ in
            return [ZMUpdateEvent()]
        }
        mockActionsProvider.fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockValue = Data()
        mockCoreCrypto.mockConversationExists = {_ in
            return false
        }
        mockCoreCrypto.mockCreateConversation = { _, _, _ in
            expectation1.fulfill()
        }

        mockMLSActionExecutor.mockCommitPendingProposals = { id in
            XCTAssertEqual(id, groupID)
            return []
        }

        mockActionsProvider.claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_MockValue = [.init(client: "123", domain: BackendInfo.domain!, keyPackage: "", keyPackageRef: "", userID: UUID())]

        mockMLSActionExecutor.mockAddMembers = { _, id in
            XCTAssertEqual(id, groupID)
            return []
        }

        // WHEN
        try await sut.joinNewGroup(with: groupID)

        // THEN
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

    func test_ItJoinsNewGroupForGuestLinkWhenConversationExists() async throws {
        // Given
        let groupID = MLSGroupID.random()
        var conversation: ZMConversation!

        await uiMOC.perform { [self] in
            // A group with pending proposal in the future
            conversation = createConversation(in: uiMOC)
            conversation.mlsGroupID = groupID
            conversation.messageProtocol = .mls
            conversation.domain = "example.com"
        }

        mockMLSActionExecutor.mockJoinGroup = { _, _ in
            return [ZMUpdateEvent()]
        }
        mockActionsProvider.fetchConversationGroupInfoConversationIdDomainSubgroupTypeContext_MockValue = Data()
        mockCoreCrypto.mockConversationExists = {_ in
            return true
        }

        mockMLSActionExecutor.mockCommitPendingProposals = { id in
            XCTAssertEqual(id, groupID)
            return []
        }

        mockActionsProvider.claimKeyPackagesUserIDDomainExcludedSelfClientIDIn_MockValue = [.init(client: "123", domain: BackendInfo.domain!, keyPackage: "", keyPackageRef: "", userID: UUID())]

        mockMLSActionExecutor.mockAddMembers = { _, id in
            XCTAssertEqual(id, groupID)
            return []
        }

        // WHEN
        _ = try await sut.joinNewGroup(with: groupID)

        // THEN
        XCTAssertTrue(waitForCustomExpectations(withTimeout: 0.5))
    }

}
