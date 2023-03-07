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
import CoreCryptoSwift

class MLSActionExecutorTests: ZMBaseManagedObjectTest {

    var mockCoreCrypto: MockCoreCrypto!
    var mockActionsProvider: MockMLSActionsProvider!
    var sut: MLSActionExecutor!

    override func setUp() {
        super.setUp()
        mockCoreCrypto = MockCoreCrypto()
        mockActionsProvider = MockMLSActionsProvider()
        sut = MLSActionExecutor(
            coreCrypto: MockSafeCoreCrypto(coreCrypto: mockCoreCrypto),
            context: uiMOC,
            actionsProvider: mockActionsProvider
        )
    }

    override func tearDown() {
        mockCoreCrypto = nil
        mockActionsProvider = nil
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

    // MARK: - Add members

    func test_AddMembers() async throws {
        // Given
        let groupID = MLSGroupID(.random())
        let invitees = [Invitee(id: .random(), kp: .random())]

        let mockCommit = Bytes.random()
        let mockWelcome = Bytes.random()
        let mockUpdateEvent = mockMemberJoinUpdateEvent()
        let mockPublicGroupState = PublicGroupStateBundle(
            encryptionType: .plaintext,
            ratchetTreeType: .full,
            payload: .random()
        )
        let mockMemberAddedMessages = MemberAddedMessages(
            commit: mockCommit,
            welcome: mockWelcome,
            publicGroupState: mockPublicGroupState
        )

        // Mock add clients.
        var mockAddClientsArguments = [(Bytes, [Invitee])]()
        mockCoreCrypto.mockAddClientsToConversation = {
            mockAddClientsArguments.append(($0, $1))
            return mockMemberAddedMessages
        }

        // Mock send commit bundle.
        var mockSendCommitBundleArguments = [Data]()
        mockActionsProvider.sendCommitBundleMocks.append({
            mockSendCommitBundleArguments.append($0)
            return [mockUpdateEvent]
        })

        // Mock merge commit.
        var mockCommitAcceptedArguments = [Bytes]()
        mockCoreCrypto.mockCommitAccepted = {
            mockCommitAcceptedArguments.append($0)
        }

        // When
        let updateEvents = try await sut.addMembers(invitees, to: groupID)

        // Then core crypto added the members.
        XCTAssertEqual(mockAddClientsArguments.count, 1)
        XCTAssertEqual(mockAddClientsArguments.first?.0, groupID.bytes)
        XCTAssertEqual(mockAddClientsArguments.first?.1, invitees)

        // Then the commit bundle was sent.
        let expectedCommitBundle = CommitBundle(
            welcome: mockWelcome,
            commit: mockCommit,
            publicGroupState: mockPublicGroupState
        )
        XCTAssertEqual(mockSendCommitBundleArguments.count, 1)
        XCTAssertEqual(mockSendCommitBundleArguments.first, try expectedCommitBundle.protobufData())

        // Then the commit was merged.
        XCTAssertEqual(mockCommitAcceptedArguments.count, 1)
        XCTAssertEqual(mockCommitAcceptedArguments.first, groupID.bytes)

        // Then the update event was returned.
        XCTAssertEqual(updateEvents, [mockUpdateEvent])
    }

    // MARK: - Remove clients

    func test_RemoveClients() async throws {
        // Given
        let groupID = MLSGroupID(.random())
        let mlsClientID = MLSClientID(
            userID: UUID.create().uuidString,
            clientID: UUID.create().uuidString,
            domain: "example.com"
        )

        let clientIds =  [mlsClientID].compactMap { $0.string.utf8Data?.bytes }

        let mockCommit = Bytes.random()
        let mockUpdateEvent = mockMemberLeaveUpdateEvent()
        let mockPublicGroupState = PublicGroupStateBundle(
            encryptionType: .plaintext,
            ratchetTreeType: .full,
            payload: .random()
        )
        let mockCommitBundle = CommitBundle(
            welcome: nil,
            commit: mockCommit,
            publicGroupState: mockPublicGroupState
        )

        // Mock remove clients.
        var mockRemoveClientsArguments = [(Bytes, [ClientId])]()
        mockCoreCrypto.mockRemoveClientsFromConversation = {
            mockRemoveClientsArguments.append(($0, $1))
            return mockCommitBundle
        }

        // Mock send commit bundle.
        var mockSendCommitBundleArguments = [Data]()
        mockActionsProvider.sendCommitBundleMocks.append({
            mockSendCommitBundleArguments.append($0)
            return [mockUpdateEvent]
        })

        // Mock merge commit.
        var mockCommitAcceptedArguments = [Bytes]()
        mockCoreCrypto.mockCommitAccepted = {
            mockCommitAcceptedArguments.append($0)
        }

        // When
        let updateEvents = try await sut.removeClients(clientIds, from: groupID)

        // Then core crypto removes the members.
        XCTAssertEqual(mockRemoveClientsArguments.count, 1)
        XCTAssertEqual(mockRemoveClientsArguments.first?.0, groupID.bytes)
        XCTAssertEqual(mockRemoveClientsArguments.first?.1, clientIds)

        // Then the commit bundle was sent.
        XCTAssertEqual(mockSendCommitBundleArguments.count, 1)
        XCTAssertEqual(mockSendCommitBundleArguments.first, try mockCommitBundle.protobufData())

        // Then the commit was merged.
        XCTAssertEqual(mockCommitAcceptedArguments.count, 1)
        XCTAssertEqual(mockCommitAcceptedArguments.first, groupID.bytes)

        // Then the update event was returned.
        XCTAssertEqual(updateEvents, [mockUpdateEvent])
    }

    // MARK: - Update key material

    func test_UpdateKeyMaterial() async throws {
        // Given
        let groupID = MLSGroupID(.random())

        let mockCommit = Bytes.random()
        let mockPublicGroupState = PublicGroupStateBundle(
            encryptionType: .plaintext,
            ratchetTreeType: .full,
            payload: .random()
        )
        let mockCommitBundle = CommitBundle(
            welcome: nil,
            commit: mockCommit,
            publicGroupState: mockPublicGroupState
        )

        // Mock Update key material.
        var mockUpdateKeyMaterialArguments = [Bytes]()
        mockCoreCrypto.mockUpdateKeyingMaterial = {
            mockUpdateKeyMaterialArguments.append($0)
            return mockCommitBundle
        }

        // Mock send commit bundle.
        var mockSendCommitBundleArguments = [Data]()
        mockActionsProvider.sendCommitBundleMocks.append({
            mockSendCommitBundleArguments.append($0)
            return []
        })

        // Mock merge commit.
        var mockCommitAcceptedArguments = [Bytes]()
        mockCoreCrypto.mockCommitAccepted = {
            mockCommitAcceptedArguments.append($0)
        }

        // When
        let updateEvents = try await sut.updateKeyMaterial(for: groupID)

        // Then core crypto update key materials.
        XCTAssertEqual(mockUpdateKeyMaterialArguments.count, 1)
        XCTAssertEqual(mockUpdateKeyMaterialArguments.first, groupID.bytes)

        // Then the commit bundle was sent.
        XCTAssertEqual(mockSendCommitBundleArguments.count, 1)
        XCTAssertEqual(mockSendCommitBundleArguments.first, try mockCommitBundle.protobufData())

        // Then the commit was merged.
        XCTAssertEqual(mockCommitAcceptedArguments.count, 1)
        XCTAssertEqual(mockCommitAcceptedArguments.first, groupID.bytes)

        // Then no update events were returned.
        XCTAssertEqual(updateEvents, [ZMUpdateEvent]())
    }

    // MARK: - Commit pending proposals

    func test_CommitPendingProposals() async throws {
        // Given
        let groupID = MLSGroupID(.random())

        let mockCommit = Bytes.random()
        let mockWelcome = Bytes.random()
        let mockUpdateEvent = mockMemberLeaveUpdateEvent()
        let mockPublicGroupState = PublicGroupStateBundle(
            encryptionType: .plaintext,
            ratchetTreeType: .full,
            payload: .random()
        )
        let mockCommitBundle = CommitBundle(
            welcome: mockWelcome,
            commit: mockCommit,
            publicGroupState: mockPublicGroupState
        )

        // Mock Commit pending proposals.
        var mockCommitPendingProposals = [Bytes]()
        mockCoreCrypto.mockCommitPendingProposals = {
            mockCommitPendingProposals.append($0)
            return CommitBundle(
                welcome: mockWelcome,
                commit: mockCommit,
                publicGroupState: mockPublicGroupState
            )
        }

        // Mock send commit bundle.
        var mockSendCommitBundleArguments = [Data]()
        mockActionsProvider.sendCommitBundleMocks.append({
            mockSendCommitBundleArguments.append($0)
            return [mockUpdateEvent]
        })

        // Mock merge commit.
        var mockCommitAcceptedArguments = [Bytes]()
        mockCoreCrypto.mockCommitAccepted = {
            mockCommitAcceptedArguments.append($0)
        }

        // When
        let updateEvents = try await sut.commitPendingProposals(in: groupID)

        // Then core crypto commit pending proposals.
        XCTAssertEqual(mockCommitPendingProposals.count, 1)
        XCTAssertEqual(mockCommitPendingProposals.first, groupID.bytes)

        // Then the commit bundle was sent.
        XCTAssertEqual(mockSendCommitBundleArguments.count, 1)
        XCTAssertEqual(mockSendCommitBundleArguments.first, try mockCommitBundle.protobufData())

        // Then the commit was merged.
        XCTAssertEqual(mockCommitAcceptedArguments.count, 1)
        XCTAssertEqual(mockCommitAcceptedArguments.first, groupID.bytes)

        // Then the update event was returned.
        XCTAssertEqual(updateEvents, [mockUpdateEvent])
    }

    // MARK: - Join Group

    func test_JoinGroup() async throws {
        // Given
        let groupID = MLSGroupID(.random())
        let mockCommit = Bytes.random()
        let mockPublicGroupState = Bytes.random().data
        let mockPublicGroupStateBundle = PublicGroupStateBundle(
            encryptionType: .plaintext,
            ratchetTreeType: .full,
            payload: []
        )
        let mockCommitBundle = CommitBundle(
            welcome: nil,
            commit: mockCommit,
            publicGroupState: mockPublicGroupStateBundle
        )
        // TODO: Mock properly
        let mockUpdateEvents = [ZMUpdateEvent]()

        // Mock join by external commit
        var mockJoinByExternalCommitArguments = [Bytes]()

        mockCoreCrypto.mockJoinByExternalCommit = { groupState, _ in
            mockJoinByExternalCommitArguments.append(groupState)
            return .init(
                conversationId: groupID.bytes,
                commit: mockCommit,
                publicGroupState: mockPublicGroupStateBundle
            )
        }

        // Mock send commit bundle
        var mockSendCommitBundleArguments = [Data]()
        mockActionsProvider.sendCommitBundleMocks.append({
            mockSendCommitBundleArguments.append($0)
            return mockUpdateEvents
        })

        // Mock merge pending group
        var mockMergePendingGroupArguments = [Bytes]()
        mockCoreCrypto.mockMergePendingGroupFromExternalCommit = { conversationId in
            mockMergePendingGroupArguments.append(conversationId)
        }

        // When
        let updateEvents = try await sut.joinGroup(groupID, publicGroupState: mockPublicGroupState)

        // Then core crypto creates conversation init bundle
        XCTAssertEqual(mockJoinByExternalCommitArguments.count, 1)
        XCTAssertEqual(mockJoinByExternalCommitArguments.first, mockPublicGroupState.bytes)

        // Then commit bundle was sent
        XCTAssertEqual(mockSendCommitBundleArguments.count, 1)
        XCTAssertEqual(mockSendCommitBundleArguments.first, try mockCommitBundle.protobufData())

        // Then pending group is merged
        XCTAssertEqual(mockMergePendingGroupArguments.count, 1)
        XCTAssertEqual(mockMergePendingGroupArguments.first, groupID.bytes)

        // Then the update event was returned
        XCTAssertEqual(updateEvents, mockUpdateEvents)
    }

    func test_JoinGroup_ThrowsErrorWithRetryRecoveryStrategy() async throws {
        // When
        try await test_JoinGroupThrowsErrorWithRecoveryStrategy(
            sendCommitBundleError: SendCommitBundleAction.Failure.mlsStaleMessage
        ) { recovery, clearPendingGroupArguments in
            // Then
            XCTAssertEqual(recovery, .retry)
            XCTAssertEqual(clearPendingGroupArguments.count, 0)
        }
    }

    func test_JoinGroup_ThrowsErrorWithGiveUpRecoveryStrategy() async throws {
        // Given
        let groupID = MLSGroupID(.random())
        let error = SendCommitBundleAction.Failure.unknown(
            status: 999,
            label: "unknown",
            message: "unknown"
        )

        // When
        try await test_JoinGroupThrowsErrorWithRecoveryStrategy(
            groupID: groupID,
            sendCommitBundleError: error
        ) { recovery, clearPendingGroupArguments in
            // Then
            XCTAssertEqual(recovery, .giveUp)
            XCTAssertEqual(clearPendingGroupArguments.count, 1)
            XCTAssertEqual(clearPendingGroupArguments.first, groupID.bytes)
        }
    }

    private typealias AssertRecoveryBlock = (
        _ recovery: MLSActionExecutor.ExternalCommitErrorRecovery,
        _ clearPendingGroupArguments: [Bytes]
    ) -> Void

    private func test_JoinGroupThrowsErrorWithRecoveryStrategy(
        groupID: MLSGroupID = MLSGroupID(.random()),
        sendCommitBundleError: Error,
        assertRecovery: AssertRecoveryBlock
    ) async throws {
        // Given
        let mockCommit = Bytes.random()
        let mockPublicGroupStateBundle = PublicGroupStateBundle(
            encryptionType: .plaintext,
            ratchetTreeType: .full,
            payload: []
        )

        // Mock join by external commit
        var mockJoinByExternalCommitArguments = [Bytes]()
        mockCoreCrypto.mockJoinByExternalCommit = { groupState, _ in
            mockJoinByExternalCommitArguments.append(groupState)
            return .init(
                conversationId: groupID.bytes,
                commit: mockCommit,
                publicGroupState: mockPublicGroupStateBundle
            )
        }

        // Mock send commit bundle
        mockActionsProvider.sendCommitBundleMocks.append({ _ in
            throw sendCommitBundleError
        })

        // Mock clear pending group
        var mockClearPendingGroupArguments = [Bytes]()
        mockCoreCrypto.mockClearPendingGroupFromExternalCommit = {
            mockClearPendingGroupArguments.append($0)
        }

        // When / Then
        do {
            _ = try await sut.joinGroup(groupID, publicGroupState: Data())
            XCTFail("expected an error")
        } catch MLSActionExecutor.Error.failedToSendExternalCommit(recovery: let recovery) {
            assertRecovery(recovery, mockClearPendingGroupArguments)
        } catch {
            XCTFail("wrong error")
        }
    }
}
