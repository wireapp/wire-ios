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

    func joinSelfGroup(with groupID: MLSGroupID) {
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

    func removeMembersFromConversation(with clientIds: [MLSClientID], for groupID: MLSGroupID) async throws {
        fatalError("not implemented")
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
            fatalError("not implemented")
        }

        return mock(parentQualifiedID, parentID)
    }

    var mockGenerateConferenceInfo: ((MLSGroupID, MLSGroupID) -> MLSConferenceInfo)?

    func generateConferenceInfo(
        parentGroupID: MLSGroupID,
        subconversationGroupID: MLSGroupID
    ) throws -> MLSConferenceInfo {
        guard let mock = mockGenerateConferenceInfo else {
            fatalError("not implemented")
        }

        return mock(parentGroupID, subconversationGroupID)
    }

    var mockOnConferenceInfoChange: ((MLSGroupID, MLSGroupID) -> AnyPublisher<MLSConferenceInfo, Never>)?

    func onConferenceInfoChange(parentGroupID: MLSGroupID, subConversationGroupID: MLSGroupID) -> AnyPublisher<MLSConferenceInfo, Never> {
        guard let mock = mockOnConferenceInfoChange else {
            fatalError("not implemented")
        }

        return mock(parentGroupID, subConversationGroupID)
    }

    var mockOnEpochChanged: (() -> AnyPublisher<MLSGroupID, Never>)?

    func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
        guard let mock = mockOnEpochChanged else {
            fatalError("not implemented")
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
            fatalError("not implemented")
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
            fatalError("not implemented")
        }

        try mock(parentQualifiedID, parentGroupID, subconversationType, selfClientID)
    }
}
