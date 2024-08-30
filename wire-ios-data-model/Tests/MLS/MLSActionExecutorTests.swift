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

import Combine
import Foundation
import WireCoreCrypto
import XCTest

@testable import WireDataModel
@testable import WireDataModelSupport

class MLSActionExecutorTests: ZMBaseManagedObjectTest {

    var mockCoreCrypto: MockCoreCryptoProtocol!
    var mockSafeCoreCrypto: MockSafeCoreCrypto!
    var mockCoreCryptoProvider: MockCoreCryptoProviderProtocol!
    var mockCommitSender: MockCommitSending!
    var mockFeatureRepository: MockFeatureRepositoryInterface!
    var sut: MLSActionExecutor!
    var cancellable: AnyCancellable!

    override func setUp() {
        super.setUp()
        mockCoreCrypto = MockCoreCryptoProtocol()
        mockCoreCrypto.e2eiIsEnabledCiphersuite_MockValue = false
        mockSafeCoreCrypto = MockSafeCoreCrypto(coreCrypto: mockCoreCrypto)
        mockCoreCryptoProvider = MockCoreCryptoProviderProtocol()
        mockCoreCryptoProvider.coreCrypto_MockValue = mockSafeCoreCrypto
        mockCommitSender = MockCommitSending()
        mockFeatureRepository = MockFeatureRepositoryInterface()

        sut = MLSActionExecutor(
            coreCryptoProvider: mockCoreCryptoProvider,
            commitSender: mockCommitSender,
            featureRepository: mockFeatureRepository
        )
    }

    override func tearDown() {
        mockCoreCrypto = nil
        mockSafeCoreCrypto = nil
        mockCoreCryptoProvider = nil
        mockCommitSender = nil
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
        let mockCommit = Data.random()
        let mockGroupInfo = GroupInfoBundle(
            encryptionType: .plaintext,
            ratchetTreeType: .full,
            payload: .random()
        )
        let mockCommitBundle = CommitBundle(
            welcome: nil,
            commit: mockCommit,
            groupInfo: mockGroupInfo
        )

        let sendCommitExpectation = XCTestExpectation(description: "send commit")
        var sendCommitContinuation: CheckedContinuation<Void, Never>?

        let beforeDecryptMessageExpectation = XCTestExpectation(description: "Task to decrypt message has been started/is running")
        let insideDecryptMessageInvertedExpectation = XCTestExpectation(description: "not yet decrypting message").inverted()
        let afterDecryptMessageExpectation = XCTestExpectation(description: "Task to decrypt message has finished")

        // Mock Update key material.
        var mockUpdateKeyMaterialArguments = [Data]()
        mockCoreCrypto.updateKeyingMaterialConversationId_MockMethod = {
            mockUpdateKeyMaterialArguments.append($0)
            return mockCommitBundle
        }

        // Mock send commit bundle.
        mockCommitSender.sendCommitBundleFor_MockMethod = { _, _ in
            await withCheckedContinuation { continuation in
                sendCommitContinuation = continuation
                sendCommitExpectation.fulfill()
            }
            return []
        }

        mockCoreCrypto.decryptMessageConversationIdPayload_MockMethod = { _, _ in
            insideDecryptMessageInvertedExpectation.fulfill()
            return DecryptedMessage(
                message: nil,
                proposals: [],
                isActive: false,
                commitDelay: 0,
                senderClientId: nil,
                hasEpochChanged: false,
                identity: .withBasicCredentials(),
                bufferedMessages: nil,
                crlNewDistributionPoints: nil
            )
        }

        // When
        Task {
            do {
                _ = try await sut.updateKeyMaterial(for: groupID)
            } catch {
                XCTFail(String(reflecting: error))
            }
        }

        // the decrypt message operation should wait for update key material to finish
        await fulfillment(of: [sendCommitExpectation])
        // the `updateKeyMaterial` is blocked/suspended, now ensure that no other call using the same groupID can enter

        Task {
            do {
                beforeDecryptMessageExpectation.fulfill()
                try await _ = sut.decryptMessage(Data.random(byteCount: 1), in: groupID)
                afterDecryptMessageExpectation.fulfill()
            } catch {
                XCTFail(String(reflecting: error))
            }
        }
        // ensure the task is executing, but we haven't entered `performNonReentrant`
        await fulfillment(of: [beforeDecryptMessageExpectation, insideDecryptMessageInvertedExpectation], timeout: 0.3)
        XCTAssertEqual(mockCoreCrypto.decryptMessageConversationIdPayload_Invocations.count, 0)

        // allow update key material to finish
        sendCommitContinuation?.resume()
        await fulfillment(of: [afterDecryptMessageExpectation], timeout: 0.5)
        XCTAssertEqual(mockCoreCrypto.decryptMessageConversationIdPayload_Invocations.count, 1)
    }

    // maybe it makes sense to test performNonReentrant directly instead
    func test_TwoOperationsOnDifferentGroupsAreExecutedConcurrently() async throws {
        // Given
        let groupID1 = MLSGroupID.random()
        let groupID2 = MLSGroupID.random()
        let mockCommit = Data.random()
        let mockGroupInfo = GroupInfoBundle(
            encryptionType: .plaintext,
            ratchetTreeType: .full,
            payload: .random()
        )
        let mockCommitBundle = CommitBundle(
            welcome: nil,
            commit: mockCommit,
            groupInfo: mockGroupInfo
        )

        let sendCommitExpectation = XCTestExpectation(description: "send commit")
        let decryptMessageExpectation = XCTestExpectation(description: "decrypted message")
        var sendCommitContinuation: CheckedContinuation<Void, Never>?

        // Mock Update key material.
        var mockUpdateKeyMaterialArguments = [Data]()
        mockCoreCrypto.updateKeyingMaterialConversationId_MockMethod = {
            mockUpdateKeyMaterialArguments.append($0)
            return mockCommitBundle
        }

        // Mock send commit bundle.
        mockCommitSender.sendCommitBundleFor_MockMethod = { _, _ in
            await withCheckedContinuation { continuation in
                sendCommitContinuation = continuation
                sendCommitExpectation.fulfill()
            }
            return []
        }

        // Mock decrypt message
        mockCoreCrypto.decryptMessageConversationIdPayload_MockMethod = { _, _ in
            decryptMessageExpectation.fulfill()
            return DecryptedMessage(
                message: nil,
                proposals: [],
                isActive: false,
                commitDelay: 0,
                senderClientId: nil,
                hasEpochChanged: false,
                identity: .withBasicCredentials(),
                bufferedMessages: nil,
                crlNewDistributionPoints: nil
            )
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
        await fulfillment(of: [sendCommitExpectation], timeout: .tenSeconds)

        Task {
            do {
                try await _ = sut.decryptMessage(Data.random(byteCount: 1), in: groupID2)
            } catch {
                XCTFail(String(reflecting: error))
            }
        }

        // the update key material operation shouldn't block the decrypt message
        await fulfillment(of: [decryptMessageExpectation], timeout: .tenSeconds)

        XCTAssertEqual(mockCoreCrypto.decryptMessageConversationIdPayload_Invocations.count, 1)
        sendCommitContinuation?.resume()
    }

    // MARK: - Process welcome message

    func test_processWelcomeMessage_ReturnsGroupID() async throws {
        // Given
        let groupID = MLSGroupID.random()
        let message = Data.random()
        let welcomeBundle = WelcomeBundle(id: groupID.data, crlNewDistributionPoints: nil)

        // Mock
        mockCoreCrypto.processWelcomeMessageWelcomeMessageCustomConfiguration_MockMethod = { _, _ in
            welcomeBundle
        }

        // When
        let result = try await sut.processWelcomeMessage(message)

        // Then
        XCTAssertEqual(groupID, result)
        XCTAssertEqual(mockCoreCrypto.processWelcomeMessageWelcomeMessageCustomConfiguration_Invocations.count, 1)
    }

    func test_processWelcomeMessage_PublishesNewDistributionPoints() async throws {
        // Given
        let distributionPoint = "example.domain.com/dp"
        let groupID = MLSGroupID.random()
        let message = Data.random()
        let welcomeBundle = WelcomeBundle(id: groupID.data, crlNewDistributionPoints: [distributionPoint])

        // Mock
        mockCoreCrypto.processWelcomeMessageWelcomeMessageCustomConfiguration_MockMethod = { _, _ in
            welcomeBundle
        }

        // Set up expectation to receive the new distribution points
        let expectation = XCTestExpectation(description: "received value")
        cancellable = sut.onNewCRLsDistributionPoints().sink { value in
            XCTAssertEqual(value, CRLsDistributionPoints(from: [distributionPoint]))
            expectation.fulfill()
        }

        // When
        _ = try await sut.processWelcomeMessage(message)

        // Then
        await fulfillment(of: [expectation], timeout: 0.5)
    }

    // MARK: - Add members

    func test_AddMembers() async throws {
        // Given
        let groupID = MLSGroupID.random()
        let keyPackages = [KeyPackage(client: "client1", domain: "exampel.com", keyPackage: Data.random().base64String(), keyPackageRef: "", userID: .create())]

        let mockCommit = Data.random()
        let mockWelcome = Data.random()
        let mockUpdateEvent = mockMemberJoinUpdateEvent()
        let mockGroupInfo = GroupInfoBundle(
            encryptionType: .plaintext,
            ratchetTreeType: .full,
            payload: .random()
        )
        let mockMemberAddedMessages = MemberAddedMessages(
            welcome: mockWelcome,
            commit: mockCommit,
            groupInfo: mockGroupInfo,
            crlNewDistributionPoints: nil
        )

        // Mock add clients.
        var mockAddClientsArguments = [(Data, [Data])]()
        mockCoreCrypto.addClientsToConversationConversationIdKeyPackages_MockMethod = {
            mockAddClientsArguments.append(($0, $1))
            return mockMemberAddedMessages
        }

        // Mock send commit bundle.
        mockCommitSender.sendCommitBundleFor_MockMethod = { _, _ in
            return [mockUpdateEvent]
        }

        // When
        let updateEvents = try await sut.addMembers(keyPackages, to: groupID)

        // Then core crypto added the members.
        XCTAssertEqual(mockAddClientsArguments.count, 1)
        XCTAssertEqual(mockAddClientsArguments.first?.0, groupID.data)
        XCTAssertEqual(mockAddClientsArguments.first?.1, keyPackages.compactMap(\.keyPackage.base64DecodedData))

        // Then the commit bundle was sent.
        let expectedCommitBundle = CommitBundle(
            welcome: mockWelcome,
            commit: mockCommit,
            groupInfo: mockGroupInfo
        )

        XCTAssertEqual(mockCommitSender.sendCommitBundleFor_Invocations.count, 1)
        XCTAssertEqual(mockCommitSender.sendCommitBundleFor_Invocations.first?.bundle, expectedCommitBundle)

        // Then the update event was returned.
        XCTAssertEqual(updateEvents, [mockUpdateEvent])
    }

    func test_AddMembers_PublishesNewDistributionPoints() async throws {
        // Given
        let distributionPoint = "example.domain.com/dp"

        // Mock adding clients returns new distribution point
        mockCoreCrypto.addClientsToConversationConversationIdKeyPackages_MockMethod = { _, _ in
            return .init(
                welcome: .random(),
                commit: .random(),
                groupInfo: .init(
                    encryptionType: .plaintext,
                    ratchetTreeType: .full,
                    payload: .random()
                ),
                crlNewDistributionPoints: [distributionPoint]
            )
        }

        // Mock commit sending
        mockCommitSender.sendCommitBundleFor_MockMethod = { _, _ in
            return []
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
        await fulfillment(of: [expectation], timeout: 0.5)
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

        let clientIds = [mlsClientID].compactMap { $0.rawValue.utf8Data }

        let mockCommit = Data.random()
        let mockUpdateEvent = mockMemberLeaveUpdateEvent()
        let mockGroupInfo = GroupInfoBundle(
            encryptionType: .plaintext,
            ratchetTreeType: .full,
            payload: .random()
        )
        let mockCommitBundle = CommitBundle(
            welcome: nil,
            commit: mockCommit,
            groupInfo: mockGroupInfo
        )

        // Mock remove clients.
        var mockRemoveClientsArguments = [(Data, [ClientId])]()
        mockCoreCrypto.removeClientsFromConversationConversationIdClients_MockMethod = {
            mockRemoveClientsArguments.append(($0, $1))
            return mockCommitBundle
        }

        // Mock send commit bundle.
        mockCommitSender.sendCommitBundleFor_MockMethod = { _, _ in
            return [mockUpdateEvent]
        }

        // When
        let updateEvents = try await sut.removeClients(clientIds, from: groupID)

        // Then core crypto removes the members.
        XCTAssertEqual(mockRemoveClientsArguments.count, 1)
        XCTAssertEqual(mockRemoveClientsArguments.first?.0, groupID.data)
        XCTAssertEqual(mockRemoveClientsArguments.first?.1, clientIds)

        // Then the commit bundle was sent.
        XCTAssertEqual(mockCommitSender.sendCommitBundleFor_Invocations.count, 1)
        XCTAssertEqual(mockCommitSender.sendCommitBundleFor_Invocations.first?.bundle, mockCommitBundle)

        // Then the update event was returned.
        XCTAssertEqual(updateEvents, [mockUpdateEvent])
    }

    // MARK: - Update key material

    func test_UpdateKeyMaterial() async throws {
        // Given
        let groupID = MLSGroupID.random()
        let mockCommit = Data.random()
        let mockGroupInfo = GroupInfoBundle(
            encryptionType: .plaintext,
            ratchetTreeType: .full,
            payload: .random()
        )
        let mockCommitBundle = CommitBundle(
            welcome: nil,
            commit: mockCommit,
            groupInfo: mockGroupInfo
        )

        // Mock Update key material.
        var mockUpdateKeyMaterialArguments = [Data]()
        mockCoreCrypto.updateKeyingMaterialConversationId_MockMethod = {
            mockUpdateKeyMaterialArguments.append($0)
            return mockCommitBundle
        }

        // Mock send commit bundle.
        mockCommitSender.sendCommitBundleFor_MockMethod = { _, _ in
            return []
        }

        // When
        let updateEvents = try await sut.updateKeyMaterial(for: groupID)

        // Then core crypto update key materials.
        XCTAssertEqual(mockUpdateKeyMaterialArguments.count, 1)
        XCTAssertEqual(mockUpdateKeyMaterialArguments.first, groupID.data)

        // Then the commit bundle was sent.
        XCTAssertEqual(mockCommitSender.sendCommitBundleFor_Invocations.count, 1)
        XCTAssertEqual(mockCommitSender.sendCommitBundleFor_Invocations.first?.bundle, mockCommitBundle)

        // Then no update events were returned.
        XCTAssertEqual(updateEvents, [ZMUpdateEvent]())
    }

    // MARK: - Commit pending proposals

    func test_CommitPendingProposals() async throws {
        // Given
        let groupID = MLSGroupID.random()

        let mockCommit = Data.random()
        let mockWelcome = Data.random()
        let mockUpdateEvent = mockMemberLeaveUpdateEvent()
        let mockGroupInfo = GroupInfoBundle(
            encryptionType: .plaintext,
            ratchetTreeType: .full,
            payload: .random()
        )
        let mockCommitBundle = CommitBundle(
            welcome: mockWelcome,
            commit: mockCommit,
            groupInfo: mockGroupInfo
        )

        // Mock Commit pending proposals.
        var mockCommitPendingProposals = [Data]()
        mockCoreCrypto.commitPendingProposalsConversationId_MockMethod = {
            mockCommitPendingProposals.append($0)
            return CommitBundle(
                welcome: mockWelcome,
                commit: mockCommit,
                groupInfo: mockGroupInfo
            )
        }

        // Mock send commit bundle.
        mockCommitSender.sendCommitBundleFor_MockMethod = { _, _ in
            return [mockUpdateEvent]
        }

        // When
        let updateEvents = try await sut.commitPendingProposals(in: groupID)

        // Then core crypto commit pending proposals.
        XCTAssertEqual(mockCommitPendingProposals.count, 1)
        XCTAssertEqual(mockCommitPendingProposals.first, groupID.data)

        // Then the commit bundle was sent.
        XCTAssertEqual(mockCommitSender.sendCommitBundleFor_Invocations.count, 1)
        XCTAssertEqual(mockCommitSender.sendCommitBundleFor_Invocations.first?.bundle, mockCommitBundle)

        // Then the update event was returned.
        XCTAssertEqual(updateEvents, [mockUpdateEvent])
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
            payload: Data()
        )
        let mockCommitBundle = CommitBundle(
            welcome: nil,
            commit: mockCommit,
            groupInfo: mockGroupInfoBundle
        )
        // swiftlint:disable:next todo_requires_jira_link
        // TODO: Mock properly
        let mockUpdateEvents = [ZMUpdateEvent]()

        // Mock join by external commit
        var mockJoinByExternalCommitArguments = [Data]()

        // Mock MLS feature config
        mockFeatureRepository.fetchMLS_MockValue = Feature.MLS(
            status: .enabled,
            config: .init(defaultCipherSuite: .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519)
        )

        mockCoreCrypto.joinByExternalCommitGroupInfoCustomConfigurationCredentialType_MockMethod = { groupState, _, _ in
            mockJoinByExternalCommitArguments.append(groupState)
            return .init(
                conversationId: groupID.data,
                commit: mockCommit,
                groupInfo: mockGroupInfoBundle,
                crlNewDistributionPoints: nil
            )
        }

        // Mock send commit bundle
        mockCommitSender.sendExternalCommitBundleFor_MockMethod = { _, _ in
            return mockUpdateEvents
        }

        // When
        let updateEvents = try await sut.joinGroup(groupID, groupInfo: mockGroupInfo)

        // Then core crypto creates conversation init bundle
        XCTAssertEqual(mockJoinByExternalCommitArguments.count, 1)
        XCTAssertEqual(mockJoinByExternalCommitArguments.first, mockGroupInfo)

        // Then commit bundle was sent
        XCTAssertEqual(mockCommitSender.sendExternalCommitBundleFor_Invocations.count, 1)
        XCTAssertEqual(mockCommitSender.sendExternalCommitBundleFor_Invocations.first?.bundle, mockCommitBundle)

        // Then the update event was returned
        XCTAssertEqual(updateEvents, mockUpdateEvents)
    }

    func test_JoinGroup_PublishesNewDistributionPoints() async throws {
        // Given
        let distributionPoint = "example.domain.com/dp"

        // Mock joining by external commit
        mockCoreCrypto.joinByExternalCommitGroupInfoCustomConfigurationCredentialType_MockMethod = { _, _, _ in

            return .init(
                conversationId: .random(),
                commit: .random(),
                groupInfo: .init(
                    encryptionType: .plaintext,
                    ratchetTreeType: .full,
                    payload: .random()
                ),
                crlNewDistributionPoints: [distributionPoint]
            )
        }

        // Mock external commit sending
        mockCommitSender.sendExternalCommitBundleFor_MockMethod = { _, _ in
            return []
        }

        // Mock MLS feature config
        mockFeatureRepository.fetchMLS_MockValue = Feature.MLS(
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
        await fulfillment(of: [expectation], timeout: 0.5)
    }

    // MARK: - Decrypt Message

    func test_decryptMessage() async throws {

        // Given
        let groupID = MLSGroupID.random()
        let encryptedMessage = Data.random(byteCount: 1)
        let decryptedMessage = DecryptedMessage(
            message: nil,
            proposals: [],
            isActive: false,
            commitDelay: 0,
            senderClientId: nil,
            hasEpochChanged: false,
            identity: .withBasicCredentials(),
            bufferedMessages: nil,
            crlNewDistributionPoints: nil
        )

        mockCoreCrypto.decryptMessageConversationIdPayload_MockMethod = { _, _ in
            return decryptedMessage
        }

        // When
        let result = try await sut.decryptMessage(encryptedMessage, in: groupID)

        // Then
        XCTAssertEqual(result, decryptedMessage)
        XCTAssertEqual(mockCoreCrypto.decryptMessageConversationIdPayload_Invocations.count, 1)
    }

}
