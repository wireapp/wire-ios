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
import WireCoreCrypto
import Combine

@testable import WireDataModel

final class MockMLSActionExecutor: MLSActionExecutorProtocol {

    // Using a serial dispatch queue for thread safe access to the properties.
    // With `MLSActionExecutorProtocol.onEpochChanged` being declared async the
    // `MockMLSActionExecutor` could be declared as actor.
    private let serialQueue = DispatchQueue(label: "MockMLSActionExecutor")

    // MARK: - Add members

    typealias AddMembersMock = (([Invitee], MLSGroupID) async throws -> [ZMUpdateEvent])
    private var _mockAddMembers: AddMembersMock?
    var mockAddMembers: AddMembersMock? {
        get { serialQueue.sync { _mockAddMembers } }
        set { serialQueue.sync { _mockAddMembers = newValue } }
    }

    func addMembers(_ invitees: [Invitee], to groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        guard let mock = mockAddMembers else {
            fatalError("no mock for `addMembers`")
        }

        return try await mock(invitees, groupID)
    }

    // MARK: - Remove clients

    typealias RemoveClientsMock = (([ClientId], MLSGroupID) async throws -> [ZMUpdateEvent])
    private var mockRemoveClients_: RemoveClientsMock?
    var mockRemoveClients: RemoveClientsMock? {
        get { serialQueue.sync { mockRemoveClients_ } }
        set { serialQueue.sync { mockRemoveClients_ = newValue } }
    }

    func removeClients(_ clients: [ClientId], from groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        guard let mock = mockRemoveClients else {
            fatalError("no mock for `removeClients`")
        }

        return try await mock(clients, groupID)
    }

    // MARK: - Update key material

    typealias UpdateKeyMaterialMock = ((MLSGroupID) async throws -> [ZMUpdateEvent])
    private var mockUpdateKeyMaterial_: UpdateKeyMaterialMock?
    var mockUpdateKeyMaterial: UpdateKeyMaterialMock? {
        get { serialQueue.sync { mockUpdateKeyMaterial_ } }
        set { serialQueue.sync { mockUpdateKeyMaterial_ = newValue } }
    }

    private var updateKeyMaterialCount_ = 0
    var updateKeyMaterialCount: Int {
        get { serialQueue.sync { updateKeyMaterialCount_ } }
        set { serialQueue.sync { updateKeyMaterialCount_ = newValue } }
    }

    func updateKeyMaterial(for groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        guard let mock = mockUpdateKeyMaterial else {
            fatalError("no mock for `updateKeyMaterial`")
        }

        updateKeyMaterialCount += 1
        return try await mock(groupID)
    }

    // MARK: - Commit pending proposals

    typealias CommitPendingProposalsMock = ((MLSGroupID) async throws -> [ZMUpdateEvent])
    private var mockCommitPendingProposals_: CommitPendingProposalsMock?
    var mockCommitPendingProposals: CommitPendingProposalsMock? {
        get { serialQueue.sync { mockCommitPendingProposals_ } }
        set { serialQueue.sync { mockCommitPendingProposals_ = newValue } }
    }

    private var commitPendingProposalsCount_ = 0
    var commitPendingProposalsCount: Int {
        get { serialQueue.sync { commitPendingProposalsCount_ } }
        set { serialQueue.sync { commitPendingProposalsCount_ = newValue } }
    }

    func commitPendingProposals(in groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        guard let mock = mockCommitPendingProposals else {
            fatalError("no mock for `commitPendingProposals`")
        }

        commitPendingProposalsCount += 1
        return try await mock(groupID)
    }

    // MARK: - Join group

    typealias JoinGroupMock = ((MLSGroupID, Data) async throws -> [ZMUpdateEvent])
    private var mockJoinGroup_: JoinGroupMock?
    var mockJoinGroup: JoinGroupMock? {
        get { serialQueue.sync { mockJoinGroup_ } }
        set { serialQueue.sync { mockJoinGroup_ = newValue } }
    }

    private var mockJoinGroupCount_ = 0
    var mockJoinGroupCount: Int {
        get { serialQueue.sync { mockJoinGroupCount_ } }
        set { serialQueue.sync { mockJoinGroupCount_ = newValue } }
    }

    func joinGroup(_ groupID: MLSGroupID, groupInfo: Data) async throws -> [ZMUpdateEvent] {
        guard let mock = mockJoinGroup else {
            fatalError("no mock for `joinGroup`")
        }

        mockJoinGroupCount += 1
        return try await mock(groupID, groupInfo)
    }

    // MARK: - On epoch changed

    typealias OnEpochChangedMock = () -> AnyPublisher<MLSGroupID, Never>
    private var mockOnEpochChanged_: OnEpochChangedMock?
    var mockOnEpochChanged: OnEpochChangedMock? {
        get { serialQueue.sync { mockOnEpochChanged_ } }
        set { serialQueue.sync { mockOnEpochChanged_ = newValue } }
    }

    private var mockOnEpochChangedCount_ = 0
    var mockOnEpochChangedCount: Int {
        get { serialQueue.sync { mockOnEpochChangedCount_ } }
        set { serialQueue.sync { mockOnEpochChangedCount_ = newValue } }
    }

    func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
        guard let mock = mockOnEpochChanged else {
            fatalError("no mock for `onEpochChanged`")
        }

        mockOnEpochChangedCount += 1
        return mock()
    }
}
