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
import WireDataModel
import Combine

// Temporary Mock until we find a way to use a single mocked `mlsServiceProcotol` accross frameworks
class MockMLSService: MLSServiceInterface {

    func createSelfGroup(for groupID: MLSGroupID) {
        fatalError("not implemented")
    }

    func joinNewGroup(with groupID: MLSGroupID) async throws {
        fatalError("not implemented")
    }

    func joinGroup(with groupID: MLSGroupID) async throws {
        fatalError("not implemented")
    }

    func commitPendingProposals(in groupID: MLSGroupID) async throws {
    }

    func uploadKeyPackagesIfNeeded() {
        fatalError("not implemented")
    }

    func createGroup(for groupID: MLSGroupID) throws {
        fatalError("not implemented")
    }

    func conversationExists(groupID: MLSGroupID) -> Bool {
        fatalError("not implemented")
    }

    func processWelcomeMessage(welcomeMessage: String) throws -> MLSGroupID {
        fatalError("not implemented")
    }

    func encrypt(message: [Byte], for groupID: MLSGroupID) throws -> [Byte] {
        return message
    }

    func decrypt(message: String, for groupID: MLSGroupID, subconversationType: SubgroupType?) throws -> MLSDecryptResult? {
        fatalError("not implemented")
    }

    func addMembersToConversation(with users: [MLSUser], for groupID: MLSGroupID) async throws {
        fatalError("not implemented")
    }

    var mockRemoveMembersFromConversation: (([MLSClientID], MLSGroupID) throws -> Void)?

    func removeMembersFromConversation(with clientIds: [MLSClientID], for groupID: MLSGroupID) async throws {
        guard let mock = mockRemoveMembersFromConversation else {
            fatalError("missing mock for `removeMembersFromConversation`")
        }

        try mock(clientIds, groupID)
    }

    func registerPendingJoin(_ group: MLSGroupID) {
        fatalError("not implemented")
    }

    var didCallPerformPendingJoins: Bool = false
    func performPendingJoins() {
        didCallPerformPendingJoins = true
    }

    var didCallCommitPendingProposals: Bool = false
    func commitPendingProposals() async throws {
        didCallCommitPendingProposals = true
    }

    func scheduleCommitPendingProposals(groupID: MLSGroupID, at commitDate: Date) {
        fatalError("not implemented")
    }

    func wipeGroup(_ groupID: MLSGroupID) {
        fatalError("not implemented")
    }

    var mockCreateOrJoinSubgroup: ((QualifiedID, MLSGroupID) -> MLSGroupID)?

    func createOrJoinSubgroup(
        parentQualifiedID: QualifiedID,
        parentID: MLSGroupID
    ) async throws -> MLSGroupID {
        guard let mock = mockCreateOrJoinSubgroup else {
            fatalError("missing mock for `createOrJoinSubgroup`")
        }

        return mock(parentQualifiedID, parentID)
    }

    var mockGenerateConferenceInfo: ((MLSGroupID, MLSGroupID) -> MLSConferenceInfo)?

    func generateConferenceInfo(
        parentGroupID: MLSGroupID,
        subconversationGroupID: MLSGroupID
    ) throws -> MLSConferenceInfo {
        guard let mock = mockGenerateConferenceInfo else {
            fatalError("missing mock for `generateConferenceInfo`")
        }

        return mock(parentGroupID, subconversationGroupID)
    }

    var mockOnConferenceInfoChange: ((MLSGroupID, MLSGroupID) -> AnyPublisher<MLSConferenceInfo, Never>)?

    func onConferenceInfoChange(parentGroupID: MLSGroupID, subConversationGroupID: MLSGroupID) -> AnyPublisher<MLSConferenceInfo, Never> {
        guard let mock = mockOnConferenceInfoChange else {
            fatalError("missing mock for `onConferenceInfoChange`")
        }

        return mock(parentGroupID, subConversationGroupID)
    }

    var mockOnEpochChanged: (() -> AnyPublisher<MLSGroupID, Never>)?

    func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
        guard let mock = mockOnEpochChanged else {
            fatalError("missing mock for `onEpochChanged`")
        }

        return mock()
    }

    var mockLeaveSubconversation: ((QualifiedID, MLSGroupID, SubgroupType) throws -> Void)?

    func leaveSubconversation(
        parentQualifiedID: QualifiedID,
        parentGroupID: MLSGroupID,
        subconversationType: SubgroupType
    ) async throws {
        guard let mock = mockLeaveSubconversation else {
            fatalError("missing mock for `leaveSubconversation`")
        }

        try mock(parentQualifiedID, parentGroupID, subconversationType)
    }

    var mockLeaveSubconversationIfNeeded: ((QualifiedID, MLSGroupID, SubgroupType, MLSClientID) throws -> Void)?

    func leaveSubconversationIfNeeded(
        parentQualifiedID: QualifiedID,
        parentGroupID: MLSGroupID,
        subconversationType: SubgroupType,
        selfClientID: MLSClientID
    ) async throws {
        guard let mock = mockLeaveSubconversationIfNeeded else {
            fatalError("missing mock for `leaveSubconversationIfNeeded`")
        }

        try mock(parentQualifiedID, parentGroupID, subconversationType, selfClientID)
    }

    var mockGenerateNewEpoch: ((MLSGroupID) -> Void)?

    func generateNewEpoch(groupID: MLSGroupID) async throws {
        guard let mock = mockGenerateNewEpoch else {
            fatalError("missing mock for `generateNewEpoch`")
        }

        return mock(groupID)
    }

    var mockSubconversationMembers: ((MLSGroupID) -> [MLSClientID])?

    func subconversationMembers(for subconversationGroupID: MLSGroupID) throws -> [MLSClientID] {
        guard let mock = mockSubconversationMembers else {
            fatalError("missing mock for `subconversationMembers`")
        }

        return mock(subconversationGroupID)
    }

    // MARK: - Out of sync

    typealias RepairOutOfSyncConversationsMock = () -> Void
    var repairOutOfSyncConversationsMock: RepairOutOfSyncConversationsMock?

    func repairOutOfSyncConversations() {
        guard let mock = repairOutOfSyncConversationsMock else {
            return
        }
        mock()
    }

    typealias FetchAndRepairGroupMock = (MLSGroupID) -> Void
    var fetchAndRepairGroupMock: FetchAndRepairGroupMock?

    func fetchAndRepairGroup(with groupID: MLSGroupID) async {
        guard let mock = fetchAndRepairGroupMock else {
            return
        }
        mock(groupID)
    }

}
