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

class MLSActionExecutorTests: ZMBaseManagedObjectTest {

    var mockCoreCrypto: MockCoreCryptoProtocol!
    var mockSafeCoreCrypto: MockSafeCoreCrypto!
    var mockCoreCryptoProvider: MockCoreCryptoProviderProtocol!
    var mockCommitSender: MockCommitSending!
    var sut: MLSActionExecutor!

    override func setUp() {
        super.setUp()
        mockCoreCrypto = MockCoreCryptoProtocol()
        mockSafeCoreCrypto = MockSafeCoreCrypto(coreCrypto: mockCoreCrypto)
        mockCoreCryptoProvider = MockCoreCryptoProviderProtocol()
        mockCoreCryptoProvider.coreCryptoRequireMLS_MockValue = mockSafeCoreCrypto
        mockCommitSender = MockCommitSending()

        sut = MLSActionExecutor(
            coreCryptoProvider: mockCoreCryptoProvider,
            commitSender: mockCommitSender
        )
    }

    override func tearDown() {
        mockCoreCrypto = nil
        mockSafeCoreCrypto = nil
        mockCoreCryptoProvider = nil
        mockCommitSender = nil
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
        let groupID = MLSGroupID.random()
        let invitees = [Invitee(id: .random(), kp: .random())]

        let mockCommit = Data.random().bytes
        let mockWelcome = Data.random().bytes
        let mockUpdateEvent = mockMemberJoinUpdateEvent()
        let mockGroupInfo = GroupInfoBundle(
            encryptionType: .plaintext,
            ratchetTreeType: .full,
            payload: .random()
        )
        let mockMemberAddedMessages = MemberAddedMessages(
            commit: mockCommit,
            welcome: mockWelcome,
            groupInfo: mockGroupInfo
        )

        // Mock add clients.
        var mockAddClientsArguments = [([Byte], [Invitee])]()
        mockCoreCrypto.mockAddClientsToConversation = {
            mockAddClientsArguments.append(($0, $1))
            return mockMemberAddedMessages
        }

        // Mock send commit bundle.
        mockCommitSender.sendCommitBundleFor_MockMethod = { _, _ in
            return [mockUpdateEvent]
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
            groupInfo: mockGroupInfo
        )

        XCTAssertEqual(mockCommitSender.sendCommitBundleFor_Invocations.count, 1)
        XCTAssertEqual(mockCommitSender.sendCommitBundleFor_Invocations.first?.bundle, expectedCommitBundle)

        // Then the update event was returned.
        XCTAssertEqual(updateEvents, [mockUpdateEvent])
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

        let clientIds =  [mlsClientID].compactMap { $0.rawValue.utf8Data?.bytes }

        let mockCommit = Data.random().bytes
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
        var mockRemoveClientsArguments = [([Byte], [ClientId])]()
        mockCoreCrypto.mockRemoveClientsFromConversation = {
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
        XCTAssertEqual(mockRemoveClientsArguments.first?.0, groupID.bytes)
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
        let mockCommit = Data.random().bytes
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
        var mockUpdateKeyMaterialArguments = [[Byte]]()
        mockCoreCrypto.mockUpdateKeyingMaterial = {
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
        XCTAssertEqual(mockUpdateKeyMaterialArguments.first, groupID.bytes)

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

        let mockCommit = Data.random().bytes
        let mockWelcome = Data.random().bytes
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
        var mockCommitPendingProposals = [[Byte]]()
        mockCoreCrypto.mockCommitPendingProposals = {
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
        XCTAssertEqual(mockCommitPendingProposals.first, groupID.bytes)

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
        let mockCommit = Data.random().bytes
        let mockGroupInfo = Data.random()
        let mockGroupInfoBundle = GroupInfoBundle(
            encryptionType: .plaintext,
            ratchetTreeType: .full,
            payload: []
        )
        let mockCommitBundle = CommitBundle(
            welcome: nil,
            commit: mockCommit,
            groupInfo: mockGroupInfoBundle
        )
        // TODO: Mock properly
        let mockUpdateEvents = [ZMUpdateEvent]()

        // Mock join by external commit
        var mockJoinByExternalCommitArguments = [[Byte]]()

        mockCoreCrypto.mockJoinByExternalCommit = { groupState, _, _ in
            mockJoinByExternalCommitArguments.append(groupState)
            return .init(
                conversationId: groupID.bytes,
                commit: mockCommit,
                groupInfo: mockGroupInfoBundle
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
        XCTAssertEqual(mockJoinByExternalCommitArguments.first, mockGroupInfo.bytes)

        // Then commit bundle was sent
        XCTAssertEqual(mockCommitSender.sendExternalCommitBundleFor_Invocations.count, 1)
        XCTAssertEqual(mockCommitSender.sendExternalCommitBundleFor_Invocations.first?.bundle, mockCommitBundle)

        // Then the update event was returned
        XCTAssertEqual(updateEvents, mockUpdateEvents)
    }

}
