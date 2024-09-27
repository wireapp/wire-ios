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
@testable import WireDataModel

final class MockMLSActionExecutor: MLSActionExecutorProtocol {
    // MARK: Internal

    // MARK: - Process welcome message

    typealias ProcessWelcomeMessageMock = (Data) async throws -> MLSGroupID

    // MARK: - Add members

    typealias AddMembersMock = ([KeyPackage], MLSGroupID) async throws -> [ZMUpdateEvent]

    // MARK: - Remove clients

    typealias RemoveClientsMock = ([ClientId], MLSGroupID) async throws -> [ZMUpdateEvent]

    // MARK: - Update key material

    typealias UpdateKeyMaterialMock = (MLSGroupID) async throws -> [ZMUpdateEvent]

    // MARK: - Commit pending proposals

    typealias CommitPendingProposalsMock = (MLSGroupID) async throws -> [ZMUpdateEvent]

    // MARK: - Join group

    typealias JoinGroupMock = (MLSGroupID, Data) async throws -> [ZMUpdateEvent]

    // MARK: - Decrypt

    typealias DecryptMessage = (Data, MLSGroupID) async throws -> DecryptedMessage

    // MARK: - On epoch changed

    typealias OnEpochChangedMock = () -> AnyPublisher<MLSGroupID, Never>

    // MARK: - On new CRLs distribution points

    typealias OnNewCRLsDistributionPointsMock = () -> AnyPublisher<CRLsDistributionPoints, Never>

    var mockProcessWelcomeMessage: ProcessWelcomeMessageMock? {
        get { serialQueue.sync { mockProcessWelcomeMessage_ } }
        set { serialQueue.sync { mockProcessWelcomeMessage_ = newValue } }
    }

    var processWelcomeMessageCount: Int {
        get { serialQueue.sync { processWelcomeMessageCount_ } }
        set { serialQueue.sync { processWelcomeMessageCount_ = newValue } }
    }

    var mockAddMembers: AddMembersMock? {
        get { serialQueue.sync { _mockAddMembers } }
        set { serialQueue.sync { _mockAddMembers = newValue } }
    }

    var mockRemoveClients: RemoveClientsMock? {
        get { serialQueue.sync { mockRemoveClients_ } }
        set { serialQueue.sync { mockRemoveClients_ = newValue } }
    }

    var mockUpdateKeyMaterial: UpdateKeyMaterialMock? {
        get { serialQueue.sync { mockUpdateKeyMaterial_ } }
        set { serialQueue.sync { mockUpdateKeyMaterial_ = newValue } }
    }

    var updateKeyMaterialCount: Int {
        get { serialQueue.sync { updateKeyMaterialCount_ } }
        set { serialQueue.sync { updateKeyMaterialCount_ = newValue } }
    }

    var mockCommitPendingProposals: CommitPendingProposalsMock? {
        get { serialQueue.sync { mockCommitPendingProposals_ } }
        set { serialQueue.sync { mockCommitPendingProposals_ = newValue } }
    }

    var commitPendingProposalsCount: Int {
        get { serialQueue.sync { commitPendingProposalsCount_ } }
        set { serialQueue.sync { commitPendingProposalsCount_ = newValue } }
    }

    var mockJoinGroup: JoinGroupMock? {
        get { serialQueue.sync { mockJoinGroup_ } }
        set { serialQueue.sync { mockJoinGroup_ = newValue } }
    }

    var mockJoinGroupCount: Int {
        get { serialQueue.sync { mockJoinGroupCount_ } }
        set { serialQueue.sync { mockJoinGroupCount_ = newValue } }
    }

    var mockDecryptMessage: DecryptMessage? {
        get { serialQueue.sync { mockDecryptMessage_ } }
        set { serialQueue.sync { mockDecryptMessage_ = newValue } }
    }

    var mockDecryptMessageCount: Int {
        get { serialQueue.sync { mockDecryptMessageCount_ } }
        set { serialQueue.sync { mockDecryptMessageCount_ = newValue } }
    }

    var mockOnEpochChanged: OnEpochChangedMock? {
        get { serialQueue.sync { mockOnEpochChanged_ } }
        set { serialQueue.sync { mockOnEpochChanged_ = newValue } }
    }

    var mockOnEpochChangedCount: Int {
        get { serialQueue.sync { mockOnEpochChangedCount_ } }
        set { serialQueue.sync { mockOnEpochChangedCount_ = newValue } }
    }

    var mockOnNewCRLsDistributionPoints: OnNewCRLsDistributionPointsMock? {
        get { serialQueue.sync { mockOnNewCRLsDistributionPoints_ } }
        set { serialQueue.sync { mockOnNewCRLsDistributionPoints_ = newValue } }
    }

    func processWelcomeMessage(_ message: Data) async throws -> MLSGroupID {
        guard let mock = mockProcessWelcomeMessage else {
            fatalError("no mock for `processWelcomeMessage`")
        }

        processWelcomeMessageCount_ += 1
        return try await mock(message)
    }

    func addMembers(_ keyPackages: [KeyPackage], to groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        guard let mock = mockAddMembers else {
            fatalError("no mock for `addMembers`")
        }

        return try await mock(keyPackages, groupID)
    }

    func removeClients(_ clients: [ClientId], from groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        guard let mock = mockRemoveClients else {
            fatalError("no mock for `removeClients`")
        }

        return try await mock(clients, groupID)
    }

    func updateKeyMaterial(for groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        guard let mock = mockUpdateKeyMaterial else {
            fatalError("no mock for `updateKeyMaterial`")
        }

        updateKeyMaterialCount += 1
        return try await mock(groupID)
    }

    func commitPendingProposals(in groupID: MLSGroupID) async throws -> [ZMUpdateEvent] {
        guard let mock = mockCommitPendingProposals else {
            fatalError("no mock for `commitPendingProposals`")
        }

        commitPendingProposalsCount += 1
        return try await mock(groupID)
    }

    func joinGroup(_ groupID: MLSGroupID, groupInfo: Data) async throws -> [ZMUpdateEvent] {
        guard let mock = mockJoinGroup else {
            fatalError("no mock for `joinGroup`")
        }

        mockJoinGroupCount += 1
        return try await mock(groupID, groupInfo)
    }

    func decryptMessage(_ message: Data, in groupID: WireDataModel.MLSGroupID) async throws -> WireCoreCrypto
        .DecryptedMessage {
        guard let mock = mockDecryptMessage else {
            fatalError("no mock for `decryptMessage`")
        }

        mockDecryptMessageCount += 1
        return try await mock(message, groupID)
    }

    func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
        guard let mock = mockOnEpochChanged else {
            fatalError("no mock for `onEpochChanged`")
        }

        mockOnEpochChangedCount += 1
        return mock()
    }

    func onNewCRLsDistributionPoints() -> AnyPublisher<CRLsDistributionPoints, Never> {
        guard let mock = mockOnNewCRLsDistributionPoints else {
            fatalError("no mock for `onNewCRLsDistributionPoints`")
        }

        return mock()
    }

    // MARK: Private

    // Using a serial dispatch queue for thread safe access to the properties.
    // With `MLSActionExecutorProtocol.onEpochChanged` being declared async the
    // `MockMLSActionExecutor` could be declared as actor.
    private let serialQueue = DispatchQueue(label: "MockMLSActionExecutor")

    private var mockProcessWelcomeMessage_: ProcessWelcomeMessageMock?
    private var processWelcomeMessageCount_ = 0
    private var _mockAddMembers: AddMembersMock?
    private var mockRemoveClients_: RemoveClientsMock?
    private var mockUpdateKeyMaterial_: UpdateKeyMaterialMock?
    private var updateKeyMaterialCount_ = 0
    private var mockCommitPendingProposals_: CommitPendingProposalsMock?
    private var commitPendingProposalsCount_ = 0
    private var mockJoinGroup_: JoinGroupMock?
    private var mockJoinGroupCount_ = 0
    private var mockDecryptMessage_: DecryptMessage?
    private var mockDecryptMessageCount_ = 0
    private var mockOnEpochChanged_: OnEpochChangedMock?
    private var mockOnEpochChangedCount_ = 0
    private var mockOnNewCRLsDistributionPoints_: OnNewCRLsDistributionPointsMock?
}
