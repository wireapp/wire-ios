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
@testable import WireDataModel
import WireCoreCrypto
import Combine

class MockMLSActionExecutor: MLSActionExecutorProtocol {

    // MARK: - Add members

    var mockAddMembers: (([Invitee], MLSGroupID) async throws -> [ZMUpdateEvent])?

    func addMembers(_ invitees: [Invitee], to groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        guard let mock = mockAddMembers else {
            fatalError("no mock for `addMembers`")
        }

        return try await mock(invitees, groupID)
    }

    // MARK: - Remove clients

    var mockRemoveClients: (([ClientId], MLSGroupID) async throws -> [ZMUpdateEvent])?

    func removeClients(_ clients: [ClientId], from groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        guard let mock = mockRemoveClients else {
            fatalError("no mock for `removeClients`")
        }

        return try await mock(clients, groupID)
    }

    // MARK: - Update key material

    var mockUpdateKeyMaterial: ((MLSGroupID) async throws -> [ZMUpdateEvent])?
    var updateKeyMaterialCount = 0

    func updateKeyMaterial(for groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        guard let mock = mockUpdateKeyMaterial else {
            fatalError("no mock for `updateKeyMaterial`")
        }

        updateKeyMaterialCount += 1
        return try await mock(groupID)
    }

    // MARK: - Commit pending proposals

    var mockCommitPendingProposals: ((MLSGroupID) async throws -> [ZMUpdateEvent])?
    var commitPendingProposalsCount = 0

    func commitPendingProposals(in groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        guard let mock = mockCommitPendingProposals else {
            fatalError("no mock for `commitPendingProposals`")
        }

        commitPendingProposalsCount += 1
        return try await mock(groupID)
    }

    // MARK: - Join group

    var mockJoinGroup: ((MLSGroupID, Data) async throws -> [ZMUpdateEvent])?
    var mockJoinGroupCount = 0

    func joinGroup(_ groupID: MLSGroupID, groupInfo: Data) async throws -> [ZMUpdateEvent] {
        guard let mock = mockJoinGroup else {
            fatalError("no mock for `joinGroup`")
        }

        mockJoinGroupCount += 1
        return try await mock(groupID, groupInfo)
    }

    // MARK: - On epoch changed

    var mockOnEpochChanged: (() -> AnyPublisher<MLSGroupID, Never>)?
    var mockOnEpochChangedCount = 0

    func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
        guard let mock = mockOnEpochChanged else {
            fatalError("no mock for `onEpochChanged`")
        }

        mockOnEpochChangedCount += 1
        return mock()
    }
}
