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

import Combine
import Foundation
import WireCoreCrypto
import WireTestingPackage
import XCTest

@testable import WireDataModel
@testable import WireDataModelSupport

class MLSActionExecutorTests: ZMBaseManagedObjectTest {

    var mockCoreCryptoContext: MockCoreCryptoContextProtocol!
    var mockSafeCoreCrypto: MockSafeCoreCrypto!
    var mockCoreCryptoProvider: MockCoreCryptoProviderProtocol!
    var mockLegacyFeatureRepository: MockLegacyFeatureRepositoryInterface!
    var sut: MLSActionExecutor!
    var cancellable: AnyCancellable!

    override func setUp() {
        super.setUp()
        mockCoreCryptoContext = MockCoreCryptoContextProtocol()
        mockCoreCryptoContext.e2eiIsEnabledCiphersuite_MockValue = false
        mockSafeCoreCrypto = MockSafeCoreCrypto(coreCryptoContext: mockCoreCryptoContext)
        mockCoreCryptoProvider = MockCoreCryptoProviderProtocol()
        mockCoreCryptoProvider.coreCrypto_MockValue = mockSafeCoreCrypto
        mockLegacyFeatureRepository = MockLegacyFeatureRepositoryInterface()

        sut = MLSActionExecutor(
            coreCryptoProvider: mockCoreCryptoProvider,
            featureRepository: mockLegacyFeatureRepository
        )
    }

    override func tearDown() {
        mockCoreCryptoContext = nil
        mockSafeCoreCrypto = nil
        mockCoreCryptoProvider = nil
        cancellable = nil
        sut = nil
        super.tearDown()
    }

    func mockMemberJoinUpdateEvent() -> ZMUpdateEvent {
        let payload: NSDictionary = [
            "type": "conversation.member-join",
            "data": "foo"
        ]

        return ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!
    }

    func mockMemberLeaveUpdateEvent() -> ZMUpdateEvent {
        let payload: NSDictionary = [
            "type": "conversation.member-leave",
            "data": "foo"
        ]

        return ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)!
    }

    // MARK: - Non re-entrant

    // maybe it makes sense to test performNonReentrant directly instead
    func test_TwoOperationsOnSameGroupAreExecutedSerially() async throws {
        // Given
        let groupID = MLSGroupID.random()
        let updateKeyMaterialExpectation = XCTestExpectation(description: "update key material")
        var updateKeyMaterialContinuation: CheckedContinuation<Void, Never>?

        let beforeDecryptMessageExpectation =
            XCTestExpectation(description: "Task to decrypt message has been started/is running")
        let insideDecryptMessageInvertedExpectation = XCTestExpectation(description: "not yet decrypting message")
            .inverted()
        let afterDecryptMessageExpectation = XCTestExpectation(description: "Task to decrypt message has finished")

        // Mock Update key material.
        var mockUpdateKeyMaterialArguments = [WireCoreCryptoUniffi.ConversationId]()
        mockCoreCryptoContext.updateKeyingMaterialConversationId_MockMethod = {
            mockUpdateKeyMaterialArguments.append($0)
            await withCheckedContinuation { continuation in
                updateKeyMaterialContinuation = continuation
                updateKeyMaterialExpectation.fulfill()
            }
        }

        // Mock decrypt message
        let decryptedMessage = DecryptedMessage(
            message: nil,
            isActive: false,
            commitDelay: 0,
            senderClientId: nil,
            hasEpochChanged: false,
            identity: .withBasicCredentials(),
            bufferedMessages: nil,
            crlNewDistributionPoints: nil
        )

        mockCoreCryptoContext.decryptMessageConversationIdPayload_MockValue = decryptedMessage

        // When
        Task {
            do {
                _ = try await sut.updateKeyMaterial(for: groupID)
            } catch {
                XCTFail(String(reflecting: error))
            }
        }

        // the decrypt message operation should wait for update key material to finish
        await fulfillment(of: [updateKeyMaterialExpectation])
        // the `updateKeyMaterial` is blocked/suspended, now ensure that no other call using the same groupID can enter

        Task {
            do {
                beforeDecryptMessageExpectation.fulfill()
                try await _ = sut.decryptMessage(Data.random(byteCount: 1), in: groupID, context: nil)
                afterDecryptMessageExpectation.fulfill()
            } catch {
                XCTFail(String(reflecting: error))
            }
        }
        // ensure the task is executing, but we haven't entered `performNonReentrant`
        await fulfillment(of: [beforeDecryptMessageExpectation, insideDecryptMessageInvertedExpectation], timeout: 0.3)
        XCTAssertEqual(mockCoreCryptoContext.decryptMessageConversationIdPayload_Invocations.count, 0)

        // allow update key material to finish
        updateKeyMaterialContinuation?.resume()
        await fulfillment(of: [afterDecryptMessageExpectation], timeout: 0.5)
        XCTAssertEqual(mockCoreCryptoContext.decryptMessageConversationIdPayload_Invocations.count, 1)
    }

    // maybe it makes sense to test performNonReentrant directly instead
    func test_TwoOperationsOnDifferentGroupsAreExecutedConcurrently() async throws {
        // Given
        let groupID1 = MLSGroupID.random()
        let groupID2 = MLSGroupID.random()

        let decryptMessageExpectation = XCTestExpectation(description: "decrypted message")
        let updateKeyMaterialExpectation = XCTestExpectation(description: "send commit")
        var updateKeyMaterialContinuation: CheckedContinuation<Void, Never>?

        // Mock Update key material.
        var mockUpdateKeyMaterialArguments = [WireCoreCryptoUniffi.ConversationId]()
        mockCoreCryptoContext.updateKeyingMaterialConversationId_MockMethod = {
            mockUpdateKeyMaterialArguments.append($0)
            await withCheckedContinuation { continuation in
                updateKeyMaterialContinuation = continuation
                updateKeyMaterialExpectation.fulfill()
            }
        }

        // Mock decrypt message
        let decryptedMessage = DecryptedMessage(
            message: nil,
            isActive: false,
            commitDelay: 0,
            senderClientId: nil,
            hasEpochChanged: false,
            identity: .withBasicCredentials(),
            bufferedMessages: nil,
            crlNewDistributionPoints: nil
        )
        mockCoreCryptoContext.decryptMessageConversationIdPayload_MockMethod = { _, _ in
            decryptMessageExpectation.fulfill()
            return decryptedMessage
        }

        // When
        Task {
            do {
                _ = try await sut.updateKeyMaterial(for: groupID1)
            } catch {
                XCTFail(String(reflecting: error))
            }
        }

        // ensure we entered via sendCommit, block further execution
        await fulfillment(of: [updateKeyMaterialExpectation], timeout: .tenSeconds)

        Task {
            do {
                try await _ = sut.decryptMessage(Data.random(byteCount: 1), in: groupID2, context: nil)
            } catch {
                XCTFail(String(reflecting: error))
            }
        }

        // the update key material operation shouldn't block the decrypt message
        await fulfillment(of: [decryptMessageExpectation], timeout: .tenSeconds)

        XCTAssertEqual(mockCoreCryptoContext.decryptMessageConversationIdPayload_Invocations.count, 1)
        updateKeyMaterialContinuation?.resume()
    }

    // MARK: - Process welcome message

    func test_processWelcomeMessage_ReturnsGroupID() async throws {
        // Given
        let groupID = MLSGroupID.random()
        let message = Data.random()
        let welcomeBundle = WelcomeBundle(id: groupID.conversationId, crlNewDistributionPoints: nil)

        // Mock
        mockCoreCryptoContext.processWelcomeMessageWelcomeMessageCustomConfiguration_MockMethod = { _, _ in
            welcomeBundle
        }

        // When
        let result = try await sut.processWelcomeMessage(message, context: nil)

        // Then
        XCTAssertEqual(groupID, result)
        XCTAssertEqual(
            mockCoreCryptoContext.processWelcomeMessageWelcomeMessageCustomConfiguration_Invocations.count,
            1
        )
        XCTAssertEqual(mockSafeCoreCrypto.performAsyncCount, 1)
    }

    func test_processWelcomeMessage_PublishesNewDistributionPoints() async throws {
        // Given
        let distributionPoint = "example.domain.com/dp"
        let groupID = MLSGroupID.random()
        let message = Data.random()
        let welcomeBundle = WelcomeBundle(id: groupID.conversationId, crlNewDistributionPoints: [distributionPoint])

        // Mock
        mockCoreCryptoContext.processWelcomeMessageWelcomeMessageCustomConfiguration_MockMethod = { _, _ in
            welcomeBundle
        }

        // Set up expectation to receive the new distribution points
        let expectation = XCTestExpectation(description: "received value")
        cancellable = sut.onNewCRLsDistributionPoints().sink { value in
            XCTAssertEqual(value, CRLsDistributionPoints(from: [distributionPoint]))
            expectation.fulfill()
        }

        // When
        _ = try await sut.processWelcomeMessage(message, context: nil)

        // Then
        await fulfillment(of: [expectation], timeout: 1)
    }

    func test_processWelcomeMessage_transcationIsNotCreatedWhenProvided() async throws {
        // Given
        let groupID = MLSGroupID.random()
        let message = Data.random()
        let welcomeBundle = WelcomeBundle(id: groupID.conversationId, crlNewDistributionPoints: nil)

        // Mock
        mockCoreCryptoContext.processWelcomeMessageWelcomeMessageCustomConfiguration_MockMethod = { _, _ in
            welcomeBundle
        }

        // When
        let result = try await sut.processWelcomeMessage(message, context: mockCoreCryptoContext)

        // Then
        XCTAssertEqual(groupID, result)
        XCTAssertEqual(
            mockCoreCryptoContext.processWelcomeMessageWelcomeMessageCustomConfiguration_Invocations.count,
            1
        )
        XCTAssertEqual(mockSafeCoreCrypto.performAsyncCount, 0)
    }

    // MARK: - Add members

    func test_AddMembers() async throws {
        // Given
        let groupID = MLSGroupID.random()
        let keyPackages = [KeyPackage(
            client: "client1",
            domain: "exampel.com",
            keyPackage: Data.random().base64String(),
            keyPackageRef: "",
            userID: .create()
        )]

        let mockCommit = Data.random()
        let mockWelcome = Welcome(bytes: Data.random())
        let mockUpdateEvent = mockMemberJoinUpdateEvent()
        let mockGroupInfo = GroupInfoBundle(
            encryptionType: .plaintext,
            ratchetTreeType: .full,
            payload: GroupInfo(bytes: Data.random())
        )

        // Mock add clients.
        var mockAddClientsArguments = [(WireCoreCryptoUniffi.ConversationId, [WireCoreCryptoUniffi.KeyPackage])]()
        mockCoreCryptoContext.addClientsToConversationConversationIdKeyPackages_MockMethod = {
            mockAddClientsArguments.append(($0, $1))
            return []
        }

        // When
        try await sut.addMembers(keyPackages, to: groupID)

        // Then core crypto added the members.
        XCTAssertEqual(mockAddClientsArguments.count, 1)
        XCTAssertEqual(mockAddClientsArguments.first?.0, groupID.conversationId)

        XCTAssertEqual(mockAddClientsArguments.count, keyPackages.compactMap(\.coreCryptoKeyPackage).count)
        XCTAssertEqual(
            mockAddClientsArguments.first?.1.map { $0.copyBytes() },
            keyPackages.compactMap(\.coreCryptoKeyPackage).map { $0.copyBytes() }
        )
        // Then the commit bundle was sent.
        let expectedCommitBundle = CommitBundle(
            welcome: mockWelcome,
            commit: mockCommit,
            groupInfo: mockGroupInfo,
            encryptedMessage: nil
        )
    }

    func test_AddMembers_PublishesNewDistributionPoints() async throws {
        // Given
        let distributionPoint = "example.domain.com/dp"

        // Mock adding clients returns new distribution point
        mockCoreCryptoContext.addClientsToConversationConversationIdKeyPackages_MockMethod = { _, _ in
            [distributionPoint]
        }

        // Set up expectation to receive the new distribution points
        let expectation = XCTestExpectation(description: "received value")
        cancellable = sut.onNewCRLsDistributionPoints().sink { value in
            XCTAssertEqual(value, CRLsDistributionPoints(from: [distributionPoint]))
            expectation.fulfill()
        }

        // When
        _ = try await sut.addMembers([], to: .random())

        // Then
        await fulfillment(of: [expectation], timeout: 1)
    }

    // MARK: - Remove clients

    func test_RemoveClients() async throws {
        // Given
        let groupID = MLSGroupID.random()
        let mlsClientID = MLSClientID(
            userID: UUID.create().uuidString,
            clientID: UUID.create().uuidString,
            domain: "example.com"
        )

        let clientIds = [mlsClientID].compactMap { WireCoreCryptoUniffi.ClientId(bytes: $0.rawValue.utf8Data!) }

        // Mock remove clients.
        var mockRemoveClientsArguments = [(WireCoreCryptoUniffi.ConversationId, [ClientId])]()
        mockCoreCryptoContext.removeClientsFromConversationConversationIdClients_MockMethod = {
            mockRemoveClientsArguments.append(($0, $1))
        }

        // When
        try await sut.removeClients(clientIds, from: groupID)

        // Then core crypto removes the members.
        XCTAssertEqual(mockRemoveClientsArguments.count, 1)
        XCTAssertEqual(mockRemoveClientsArguments.first?.0, groupID.conversationId)
        XCTAssertEqual(mockRemoveClientsArguments.first?.1.count, clientIds.count)
    }

    // MARK: - Update key material

    func test_UpdateKeyMaterial() async throws {
        // Given
        let groupID = MLSGroupID.random()

        // Mock Update key material.
        var mockUpdateKeyMaterialArguments = [WireCoreCryptoUniffi.ConversationId]()
        mockCoreCryptoContext.updateKeyingMaterialConversationId_MockMethod = {
            mockUpdateKeyMaterialArguments.append($0)
        }

        // When
        try await sut.updateKeyMaterial(for: groupID)

        // Then core crypto update key materials.
        XCTAssertEqual(mockUpdateKeyMaterialArguments.count, 1)
        XCTAssertEqual(mockUpdateKeyMaterialArguments.first, groupID.conversationId)
    }

    // MARK: - Commit pending proposals

    func test_CommitPendingProposals() async throws {
        // Given
        let groupID = MLSGroupID.random()

        // Mock Commit pending proposals.
        var mockCommitPendingProposals = [WireCoreCryptoUniffi.ConversationId]()
        mockCoreCryptoContext.commitPendingProposalsConversationId_MockMethod = {
            mockCommitPendingProposals.append($0)
        }

        // When
        try await sut.commitPendingProposals(in: groupID)

        // Then core crypto commit pending proposals.
        XCTAssertEqual(mockCommitPendingProposals.count, 1)
        XCTAssertEqual(mockCommitPendingProposals.first, groupID.conversationId)
    }

    // MARK: - Join Group

    func test_JoinGroup() async throws {
        // Given
        let groupID = MLSGroupID.random()
        let mockCommit = Data.random()
        let mockGroupInfo = Data.random()
        let mockGroupInfoBundle = GroupInfoBundle(
            encryptionType: .plaintext,
            ratchetTreeType: .full,
            payload: GroupInfo(bytes: Data())
        )

        // Mock join by external commit
        var mockJoinByExternalCommitArguments = [WireCoreCryptoUniffi.GroupInfo]()

        // Mock MLS feature config
        mockLegacyFeatureRepository.fetchMLS_MockValue = Feature.MLS(
            status: .enabled,
            config: .init(defaultCipherSuite: .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519)
        )

        mockCoreCryptoContext
            .joinByExternalCommitGroupInfoCustomConfigurationCredentialType_MockMethod = { groupState, _, _ in
                mockJoinByExternalCommitArguments.append(groupState)
                return .init(id: MLSGroupID.random().conversationId, crlNewDistributionPoints: [])
            }

        // When
        try await sut.joinGroup(groupID, groupInfo: mockGroupInfo)

        // Then core crypto creates conversation init bundle
        XCTAssertEqual(mockJoinByExternalCommitArguments.count, 1)
        XCTAssertEqual(
            mockJoinByExternalCommitArguments.first?.copyBytes(),
            GroupInfo(bytes: mockGroupInfo).copyBytes()
        )
    }

    func test_JoinGroup_PublishesNewDistributionPoints() async throws {
        // Given
        let distributionPoint = "example.domain.com/dp"

        // Mock joining by external commit
        mockCoreCryptoContext.joinByExternalCommitGroupInfoCustomConfigurationCredentialType_MockMethod = { _, _, _ in
            .init(
                id: MLSGroupID.random().conversationId,
                crlNewDistributionPoints: [distributionPoint]
            )
        }

        // Mock MLS feature config
        mockLegacyFeatureRepository.fetchMLS_MockValue = Feature.MLS(
            status: .enabled,
            config: .init(defaultCipherSuite: .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519)
        )

        // Set up expectation to receive the new distribution points
        let expectation = XCTestExpectation(description: "received value")
        cancellable = sut.onNewCRLsDistributionPoints().sink { value in
            XCTAssertEqual(value, CRLsDistributionPoints(from: [distributionPoint]))
            expectation.fulfill()
        }

        // When
        _ = try await sut.joinGroup(.random(), groupInfo: .random())

        // Then
        await fulfillment(of: [expectation], timeout: 1)
    }

    // MARK: - Decrypt Message

    func test_decryptMessage_throwsBufferedDecryptedMessage_withCC_BufferedFutureMessageError() async throws {
        try await internalTest_decryptMessage_swallowsError(
            CoreCryptoError.Mls(.BufferedFutureMessage)
        )
    }

    func test_decryptMessage_throwsBufferedDecryptedMessage_withBufferedCommit() async throws {
        try await internalTest_decryptMessage_swallowsError(
            CoreCryptoError.Mls(.BufferedCommit)
        )
    }

    func internalTest_decryptMessage_swallowsError(_ error: Error) async throws {

        // Given
        let groupID = MLSGroupID.random()
        let encryptedMessage = Data.random(byteCount: 1)

        mockCoreCryptoContext.decryptMessageConversationIdPayload_MockError = error

        // When
        let result = try await sut.decryptMessage(encryptedMessage, in: groupID, context: nil)

        // Then
        XCTAssertEqual(mockCoreCryptoContext.decryptMessageConversationIdPayload_Invocations.count, 1)
        XCTAssertNil(result)
    }

    func test_decryptMessage_successfully() async throws {

        // Given
        let groupID = MLSGroupID.random()
        let encryptedMessage = Data.random(byteCount: 1)
        let decryptedMessage = DecryptedMessage(
            message: nil,
            isActive: false,
            commitDelay: 0,
            senderClientId: nil,
            hasEpochChanged: false,
            identity: .withBasicCredentials(),
            bufferedMessages: nil,
            crlNewDistributionPoints: nil
        )

        mockCoreCryptoContext.decryptMessageConversationIdPayload_MockValue = decryptedMessage

        // When
        let result = try await sut.decryptMessage(encryptedMessage, in: groupID, context: nil)

        // Then
        XCTAssertEqual(result?.message, decryptedMessage.message)
        XCTAssertEqual(mockCoreCryptoContext.decryptMessageConversationIdPayload_Invocations.count, 1)
        XCTAssertEqual(mockSafeCoreCrypto.performAsyncCount, 1)
    }

    func test_decryptMessage_transcationIsNotCreatedWhenProvided() async throws {
        // Given
        let groupID = MLSGroupID.random()
        let encryptedMessage = Data.random(byteCount: 1)
        let decryptedMessage = DecryptedMessage(
            message: nil,
            isActive: false,
            commitDelay: 0,
            senderClientId: nil,
            hasEpochChanged: false,
            identity: .withBasicCredentials(),
            bufferedMessages: nil,
            crlNewDistributionPoints: nil
        )

        mockCoreCryptoContext.decryptMessageConversationIdPayload_MockValue = decryptedMessage

        // When
        let result = try await sut.decryptMessage(encryptedMessage, in: groupID, context: mockCoreCryptoContext)

        // Then
        XCTAssertEqual(result?.message, decryptedMessage.message)
        XCTAssertEqual(mockCoreCryptoContext.decryptMessageConversationIdPayload_Invocations.count, 1)
        XCTAssertEqual(mockSafeCoreCrypto.performAsyncCount, 0)
    }
}
