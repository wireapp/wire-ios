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
    var mockCoreCrypto: MockCoreCryptoProtocol!
    var mockCoreCryptoProvider: MockCoreCryptoProviderProtocol!
    var mockLegacyFeatureRepository: MockLegacyFeatureRepositoryInterface!
    var sut: MLSActionExecutor!
    var cancellable: AnyCancellable!

    let keyPackageBase64 = "AAEAASA7yBDz2iZQIUSmd8XEXU00yKY+miM2zZm8+zGCIoxoRSBMOGQGlfyNJCz7PAsnzBm+xxmDB5RU8bn3vGWQqva2CCB0vQyplDYl+y9v2tNrgGQzzJQU5+4P1jq0dpT8/Z2H8wABEL9nJhqHeUIcgLY33KngcBICAAEKAAEAAgADAAcABQAABAABAAIBAAAAAGon6uEAAAAAapa28QBAQDMzJOr9GDbi0+1/7mYXqlNzOF8LSVJnTvkp8FjLHv2HKDXJE9tz8QMdK3mzk5gqenFpvz43KMXdr/XESGPy4wkAQECT4cUQTkPtvkMaqgIZ9eSI96x+325mz+V7nca9DXl/SB3JDmcBuB77jCoAjQakyjSNmSdzui0ZGX0oG40M+SkO"

    // swiftlint:disable:next line_length
    let groupInfoBase64 = "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"

    override func setUp() {
        super.setUp()
        mockCoreCryptoContext = MockCoreCryptoContextProtocol()
        mockCoreCryptoContext.e2eiIsEnabledCipherSuite_MockValue = false
        mockCoreCrypto = MockCoreCryptoProtocol()
        mockCoreCrypto.mockTransaction(context: mockCoreCryptoContext)
        mockCoreCryptoProvider = MockCoreCryptoProviderProtocol()
        mockCoreCryptoProvider.coreCrypto_MockValue = SafeCoreCrypto(
            backgroundTaskExecuter: PassthroughTaskExecuter(),
            coreCrypto: mockCoreCrypto
        )
        mockLegacyFeatureRepository = MockLegacyFeatureRepositoryInterface()

        sut = MLSActionExecutor(
            coreCryptoProvider: mockCoreCryptoProvider,
            featureRepository: mockLegacyFeatureRepository
        )
    }

    override func tearDown() {
        mockCoreCryptoContext = nil
        mockCoreCrypto = nil
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

    func mockDecryptedMessage() throws -> DecryptedMessage {
        let plaintext = Data.random(byteCount: 1)
        let senderClientId = try ClientId(
            userId: Uuid(uuid: UUID().uuidString),
            deviceId: DeviceId(id: 1),
            domain: "wire.com"
        )
        return DecryptedMessage.text(
            plaintext: plaintext,
            senderClientId: senderClientId,
            identity: .withBasicCredentials()
        )
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
        let decryptedMessage = try mockDecryptedMessage()

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
        let decryptedMessage = try mockDecryptedMessage()
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
        let welcome = Welcome(noPointer: .init())

        // Mock
        mockCoreCryptoContext
            .processWelcomeMessageWelcomeMessage_MockMethod = { _ in
                groupID.conversationId
            }

        // When
        let result = try await sut.processWelcomeMessage(welcome, context: nil)

        // Then
        XCTAssertEqual(groupID, result)
        XCTAssertEqual(
            mockCoreCryptoContext
                .processWelcomeMessageWelcomeMessage_Invocations.count,
            1
        )
        XCTAssertEqual(mockCoreCrypto.transaction_Invocations.count, 1)
    }

    func test_processWelcomeMessage_transactionIsNotCreatedWhenProvided() async throws {
        // Given
        let groupID = MLSGroupID.random()
        let welcome = Welcome(noPointer: .init())

        // Mock
        mockCoreCryptoContext
            .processWelcomeMessageWelcomeMessage_MockMethod = { _ in
                groupID.conversationId
            }

        // When
        let result = try await sut.processWelcomeMessage(welcome, context: mockCoreCryptoContext)

        // Then
        XCTAssertEqual(groupID, result)
        XCTAssertEqual(
            mockCoreCryptoContext.processWelcomeMessageWelcomeMessage_Invocations.count,
            1
        )
        XCTAssertEqual(mockCoreCrypto.transaction_Invocations.count, 0)
    }

    // MARK: - Add members

    func test_AddMembers() async throws {
        // Given
        let groupID = MLSGroupID.random()
        let keyPackages = [KeyPackage(
            client: "client1",
            domain: "exampel.com",
            keyPackage: keyPackageBase64,
            keyPackageRef: "",
            userID: .create()
        )]

        // Mock add clients.
        var mockAddClientsArguments = [(WireCoreCryptoUniffi.ConversationId, [WireCoreCryptoUniffi.KeyPackage])]()
        mockCoreCryptoContext.addClientsToConversationConversationIdKeyPackages_MockMethod = {
            mockAddClientsArguments.append(($0, $1))
        }

        // When
        try await sut.addMembers(keyPackages, to: groupID)

        // Then core crypto added the members.
        XCTAssertEqual(mockAddClientsArguments.count, 1)
        XCTAssertEqual(mockAddClientsArguments.first?.0, groupID.conversationId)

        XCTAssertEqual(mockAddClientsArguments.count, keyPackages.compactMap(\.coreCryptoKeyPackage).count)
        XCTAssertEqual(
            try mockAddClientsArguments.first?.1.map { try $0.serialize() },
            try keyPackages.compactMap(\.coreCryptoKeyPackage).map { try $0.serialize() }
        )
    }

    // MARK: - Remove clients

    func test_RemoveClients() async throws {
        // Given
        let groupID = MLSGroupID.random()
        let mlsClientID = MLSClientID.random()

        let clientIds = try [mlsClientID].map { try $0.cryptoId() }

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
        let mockGroupInfo = groupInfoBase64.base64DecodedData!

        // Mock join by external commit
        var mockJoinByExternalCommitArguments = [GroupInfo]()

        // Mock MLS feature config
        mockLegacyFeatureRepository.fetchMLS_MockValue = Feature.MLS(
            status: .enabled,
            config: .init(defaultCipherSuite: .MLS_128_DHKEMX25519_AES128GCM_SHA256_Ed25519)
        )

        let ref = CredentialRef(noPointer: .init())
        mockCoreCrypto.findCredentials_ClientId_MockValue = [ref]

        mockCoreCryptoContext
            .joinByExternalCommitGroupInfoCredentialRef_MockMethod = { groupInfo, _ in
                mockJoinByExternalCommitArguments.append(groupInfo)
                return MLSGroupID.random().conversationId
            }

        // When
        try await sut.joinGroup(groupID, groupInfo: mockGroupInfo)

        // Then core crypto creates conversation init bundle
        XCTAssertEqual(mockJoinByExternalCommitArguments.count, 1)
    }

    // MARK: - Decrypt Message

    func test_decryptMessage_throwsBufferedDecryptedMessage_withCC_BufferedFutureMessageError() async throws {
        try await internalTest_decryptMessage_swallowsError(
            CoreCryptoError.Mls(mlsError: .BufferedFutureMessage)
        )
    }

    func test_decryptMessage_throwsBufferedDecryptedMessage_withBufferedCommit() async throws {
        try await internalTest_decryptMessage_swallowsError(
            CoreCryptoError.Mls(mlsError: .BufferedCommit)
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
        let decryptedMessage = try mockDecryptedMessage()

        mockCoreCryptoContext.decryptMessageConversationIdPayload_MockValue = decryptedMessage

        // When
        let result = try await sut.decryptMessage(encryptedMessage, in: groupID, context: nil)

        // Then
        XCTAssertEqual(result, decryptedMessage)
        XCTAssertEqual(mockCoreCryptoContext.decryptMessageConversationIdPayload_Invocations.count, 1)
        XCTAssertEqual(mockCoreCrypto.transaction_Invocations.count, 1)
    }

    func test_decryptMessage_transcationIsNotCreatedWhenProvided() async throws {
        // Given
        let groupID = MLSGroupID.random()
        let encryptedMessage = Data.random(byteCount: 1)
        let decryptedMessage = try mockDecryptedMessage()

        mockCoreCryptoContext.decryptMessageConversationIdPayload_MockValue = decryptedMessage

        // When
        let result = try await sut.decryptMessage(encryptedMessage, in: groupID, context: mockCoreCryptoContext)

        // Then
        XCTAssertEqual(result, decryptedMessage)
        XCTAssertEqual(mockCoreCryptoContext.decryptMessageConversationIdPayload_Invocations.count, 1)
        XCTAssertEqual(mockCoreCrypto.transaction_Invocations.count, 0)
    }
}

extension DecryptedMessage: @retroactive Equatable {

    public static func == (
        lhs: DecryptedMessage,
        rhs: DecryptedMessage
    ) -> Bool {
        switch (lhs, rhs) {
        case let (.text(lPlaintext, lSenderClientId, lIdentity), .text(rPlaintext, rSenderClientId, rIdentity)):
            lPlaintext == rPlaintext && lSenderClientId == rSenderClientId && lIdentity == rIdentity
        case let (.commit(lIsActive, lBufferedMessages, lIdentity), .commit(rIsActive, rBufferedMessages, rIdentity)):
            lIsActive == rIsActive && lBufferedMessages == rBufferedMessages && lIdentity == rIdentity
        case let (.proposal(lDelay, lIdentity), .proposal(rDelay, rIdentity)):
            lDelay == rDelay && lIdentity == rIdentity
        default:
            false
        }
    }

}

extension BufferedDecryptedMessage: @retroactive Equatable {

    public static func == (
        lhs: BufferedDecryptedMessage,
        rhs: BufferedDecryptedMessage
    ) -> Bool {
        switch (lhs, rhs) {
        case let (.text(lPlaintext, lSenderClientId, lIdentity), .text(rPlaintext, rSenderClientId, rIdentity)):
            lPlaintext == rPlaintext && lSenderClientId == rSenderClientId && lIdentity == rIdentity
        case let (.commit(lIsActive, lIdentity), .commit(rIsActive, rIdentity)):
            lIsActive == rIsActive && lIdentity == rIdentity
        case let (.proposal(lDelay, lIdentity), .proposal(rDelay, rIdentity)):
            lDelay == rDelay && lIdentity == rIdentity
        default:
            false
        }
    }

}

extension WireIdentity: @retroactive Equatable {

    public static func == (
        lhs: WireIdentity,
        rhs: WireIdentity
    ) -> Bool {
        guard
            lhs.status == rhs.status,
            lhs.x509Identity == rhs.x509Identity,
            lhs.clientId == rhs.clientId,
            lhs.credentialType == rhs.credentialType,
            lhs.thumbprint == rhs.thumbprint
        else {
            return false
        }

        return true
    }

}
