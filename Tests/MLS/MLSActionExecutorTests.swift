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

class MLSActionExecutorTests: ZMBaseManagedObjectTest {

    var mockCoreCrypto: MockCoreCrypto!
    var mockActionsProvider: MockMLSActionsProvider!
    var sut: MLSActionExecutor!

    override func setUp() {
        super.setUp()
        mockCoreCrypto = MockCoreCrypto()
        mockActionsProvider = MockMLSActionsProvider()
        sut = MLSActionExecutor(
            coreCrypto: mockCoreCrypto,
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

        // Mock add clients.
        var mockAddClientsArguments = [(Bytes, [Invitee])]()
        mockCoreCrypto.mockAddClientsToConversation = {
            mockAddClientsArguments.append(($0, $1))
            return MemberAddedMessages(
                commit: mockCommit,
                welcome: mockWelcome,
                publicGroupState: []
            )
        }

        // Mock send commit.
        var mockSendCommitArguments = [Data]()
        mockActionsProvider.sendMessageMocks.append({
            mockSendCommitArguments.append($0)
            return [mockUpdateEvent]
        })

        // Mock merge commit.
        var mockCommitAcceptedArguments = [Bytes]()
        mockCoreCrypto.mockCommitAccepted = {
            mockCommitAcceptedArguments.append($0)
        }

        // Mock send welcome message.
        var mockSendWelcomeArguments = [Data]()
        mockActionsProvider.sendWelcomeMessageMocks.append({
            mockSendWelcomeArguments.append($0)
        })

        // When
        let updateEvents = try await sut.addMembers(invitees, to: groupID)

        // Then core crypto added the members.
        XCTAssertEqual(mockAddClientsArguments.count, 1)
        XCTAssertEqual(mockAddClientsArguments.first?.0, groupID.bytes)
        XCTAssertEqual(mockAddClientsArguments.first?.1, invitees)

        // Then the commit was sent.
        XCTAssertEqual(mockSendCommitArguments.count, 1)
        XCTAssertEqual(mockSendCommitArguments.first, mockCommit.data)

        // Then the commit was merged.
        XCTAssertEqual(mockCommitAcceptedArguments.count, 1)
        XCTAssertEqual(mockCommitAcceptedArguments.first, groupID.bytes)

        // Then the welcome was sent.
        XCTAssertEqual(mockSendWelcomeArguments.count, 1)
        XCTAssertEqual(mockSendWelcomeArguments.first, mockWelcome.data)

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

        // Mock remove clients.
        var mockRemoveClientsArguments = [(Bytes, [ClientId])]()
        mockCoreCrypto.mockRemoveClientsFromConversation = {
            mockRemoveClientsArguments.append(($0, $1))
            return CommitBundle(
                welcome: nil,
                commit: mockCommit,
                publicGroupState: []
            )
        }

        // Mock send commit.
        var mockSendCommitArguments = [Data]()
        mockActionsProvider.sendMessageMocks.append({
            mockSendCommitArguments.append($0)
            return [mockUpdateEvent]
        })

        // Mock merge commit.
        var mockCommitAcceptedArguments = [Bytes]()
        mockCoreCrypto.mockCommitAccepted = {
            mockCommitAcceptedArguments.append($0)
        }

        // Mock send welcome message.
        var mockSendWelcomeArguments = [Data]()
        mockActionsProvider.sendWelcomeMessageMocks.append({
            mockSendWelcomeArguments.append($0)
        })

        // When
        let updateEvents = try await sut.removeClients(clientIds, from: groupID)

        // Then core crypto removes the members.
        XCTAssertEqual(mockRemoveClientsArguments.count, 1)
        XCTAssertEqual(mockRemoveClientsArguments.first?.0, groupID.bytes)
        XCTAssertEqual(mockRemoveClientsArguments.first?.1, clientIds)

        // Then the commit was sent.
        XCTAssertEqual(mockSendCommitArguments.count, 1)
        XCTAssertEqual(mockSendCommitArguments.first, mockCommit.data)

        // Then the commit was merged.
        XCTAssertEqual(mockCommitAcceptedArguments.count, 1)
        XCTAssertEqual(mockCommitAcceptedArguments.first, groupID.bytes)

        // Then no welcome was sent.
        XCTAssertEqual(mockSendWelcomeArguments.count, 0)

        // Then the update event was returned.
        XCTAssertEqual(updateEvents, [mockUpdateEvent])
    }

    // MARK: - Update key material

    func test_UpdateKeyMaterial() async throws {
        // Given
        let groupID = MLSGroupID(.random())

        let mockCommit = Bytes.random()

        // Mock Update key material.
        var mockUpdateKeyMaterialArguments = [Bytes]()
        mockCoreCrypto.mockUpdateKeyingMaterial = {
            mockUpdateKeyMaterialArguments.append($0)
            return CommitBundle(
                welcome: nil,
                commit: mockCommit,
                publicGroupState: []
            )
        }

        // Mock send commit.
        var mockSendCommitArguments = [Data]()
        mockActionsProvider.sendMessageMocks.append({
            mockSendCommitArguments.append($0)
            return []
        })

        // Mock merge commit.
        var mockCommitAcceptedArguments = [Bytes]()
        mockCoreCrypto.mockCommitAccepted = {
            mockCommitAcceptedArguments.append($0)
        }

        // Mock send welcome message.
        var mockSendWelcomeArguments = [Data]()
        mockActionsProvider.sendWelcomeMessageMocks.append({
            mockSendWelcomeArguments.append($0)
        })

        // When
        let updateEvents = try await sut.updateKeyMaterial(for: groupID)

        // Then core crypto update key materials.
        XCTAssertEqual(mockUpdateKeyMaterialArguments.count, 1)
        XCTAssertEqual(mockUpdateKeyMaterialArguments.first, groupID.bytes)

        // Then the commit was sent.
        XCTAssertEqual(mockSendCommitArguments.count, 1)
        XCTAssertEqual(mockSendCommitArguments.first, mockCommit.data)

        // Then the commit was merged.
        XCTAssertEqual(mockCommitAcceptedArguments.count, 1)
        XCTAssertEqual(mockCommitAcceptedArguments.first, groupID.bytes)

        // Then no welcome was sent.
        XCTAssertEqual(mockSendWelcomeArguments.count, 0)

        // Then no update events were returned.
        XCTAssertEqual(updateEvents, [])
    }

    // MARK: - Commit pending proposals

    func test_CommitPendingProposals() async throws {
        // Given
        let groupID = MLSGroupID(.random())

        let mockCommit = Bytes.random()
        let mockWelcome = Bytes.random()
        let mockUpdateEvent = mockMemberLeaveUpdateEvent()

        // Mock Commit pending proposals.
        var mockCommitPendingProposals = [Bytes]()
        mockCoreCrypto.mockCommitPendingProposals = {
            mockCommitPendingProposals.append($0)
            return CommitBundle(
                welcome: mockWelcome,
                commit: mockCommit,
                publicGroupState: []
            )
        }

        // Mock send commit.
        var mockSendCommitArguments = [Data]()
        mockActionsProvider.sendMessageMocks.append({
            mockSendCommitArguments.append($0)
            return [mockUpdateEvent]
        })

        // Mock merge commit.
        var mockCommitAcceptedArguments = [Bytes]()
        mockCoreCrypto.mockCommitAccepted = {
            mockCommitAcceptedArguments.append($0)
        }

        // Mock send welcome message.
        var mockSendWelcomeArguments = [Data]()
        mockActionsProvider.sendWelcomeMessageMocks.append({
            mockSendWelcomeArguments.append($0)
        })

        // When
        let updateEvents = try await sut.commitPendingProposals(in: groupID)

        // Then core crypto commit pending proposals.
        XCTAssertEqual(mockCommitPendingProposals.count, 1)
        XCTAssertEqual(mockCommitPendingProposals.first, groupID.bytes)

        // Then the commit was sent.
        XCTAssertEqual(mockSendCommitArguments.count, 1)
        XCTAssertEqual(mockSendCommitArguments.first, mockCommit.data)

        // Then the commit was merged.
        XCTAssertEqual(mockCommitAcceptedArguments.count, 1)
        XCTAssertEqual(mockCommitAcceptedArguments.first, groupID.bytes)

        // Then the welcome was sent.
        XCTAssertEqual(mockSendWelcomeArguments.count, 1)
        XCTAssertEqual(mockSendWelcomeArguments.first, mockWelcome.data)

        // Then the update event was returned.
        XCTAssertEqual(updateEvents, [mockUpdateEvent])
    }

}
