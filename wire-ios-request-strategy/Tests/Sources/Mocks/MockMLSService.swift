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

class MockMLSService: MLSServiceInterface {

    var mockDecryptResult: MLSDecryptResult?
    var mockDecryptionError: MLSDecryptionService.MLSMessageDecryptionError?
    var calls = Calls()

    struct Calls {
        var decrypt: [(String, MLSGroupID, SubgroupType?)] = []
        var commitPendingProposals: [Void] = []
        var commitPendingProposalsInGroup: [MLSGroupID] = []
        var wipeGroup = [MLSGroupID]()
        var createSelfGroup = [MLSGroupID]()
        var joinGroup = [MLSGroupID]()
        var joinNewGroup = [MLSGroupID]()
    }

    func decrypt(
        message: String,
        for groupID: MLSGroupID,
        subconversationType: SubgroupType?
    ) throws -> MLSDecryptResult? {
        calls.decrypt.append((message, groupID, subconversationType))

        if let error = mockDecryptionError {
            throw error
        }

        return mockDecryptResult
    }

    var hasWelcomeMessageBeenProcessed = false

    func conversationExists(groupID: MLSGroupID) -> Bool {
        return hasWelcomeMessageBeenProcessed
    }

    var processedWelcomeMessage: String?
    var groupID: MLSGroupID?

    @discardableResult
    func processWelcomeMessage(welcomeMessage: String) throws -> MLSGroupID {
        processedWelcomeMessage = welcomeMessage
        return groupID ?? MLSGroupID(Data())
    }

    func uploadKeyPackagesIfNeeded() {

    }

    var createGroupCalls = [MLSGroupID]()

    func createGroup(for groupID: MLSGroupID) throws {
        createGroupCalls.append(groupID)
    }

    func addMembersToConversation(with users: [MLSUser], for groupID: MLSGroupID) async throws {

    }

    func removeMembersFromConversation(with clientIds: [MLSClientID], for groupID: MLSGroupID) async throws {

    }

    func encrypt(message: [Byte], for groupID: MLSGroupID) throws -> [Byte] {
        return message + [000]
    }

    var groupsPendingJoin = [MLSGroupID]()

    func registerPendingJoin(_ group: MLSGroupID) {
        groupsPendingJoin.append(group)
    }

    func performPendingJoins() {

    }

    func wipeGroup(_ groupID: MLSGroupID) {
        calls.wipeGroup.append(groupID)
    }

    func commitPendingProposals() async throws {
        calls.commitPendingProposals.append(())
    }

    func commitPendingProposals(in groupID: MLSGroupID) async throws {
        calls.commitPendingProposalsInGroup.append(groupID)
    }

    func createOrJoinSubgroup(
        parentQualifiedID: QualifiedID,
        parentID: MLSGroupID
    ) async throws -> MLSGroupID {
        fatalError("not implemented")
    }

    func generateConferenceInfo(
        parentGroupID: MLSGroupID,
        subconversationGroupID: MLSGroupID
    ) throws -> MLSConferenceInfo {
        fatalError("not implemented")
    }

    func onConferenceInfoChange(parentGroupID: MLSGroupID, subConversationGroupID: MLSGroupID) -> AnyPublisher<MLSConferenceInfo, Never> {
        fatalError("not implemented")
    }

    func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
        fatalError("not implemented")
    }

    var mockCreateSelfGroup: ((MLSGroupID) -> Void)?
    func createSelfGroup(for groupID: MLSGroupID) {
        calls.createSelfGroup.append(groupID)
        mockCreateSelfGroup?(groupID)
    }

    func joinNewGroup(with groupID: MLSGroupID) async throws {
        calls.joinNewGroup.append(groupID)
    }

    var mockJoinGroup: ((MLSGroupID) throws -> Void)?
    func joinGroup(with groupID: MLSGroupID) async throws {
        calls.joinGroup.append(groupID)
        try mockJoinGroup?(groupID)
    }

    func leaveSubconversation(
        parentQualifiedID: QualifiedID,
        parentGroupID: MLSGroupID,
        subconversationType: SubgroupType
    ) async throws {
        fatalError("not implemented")
    }

    func leaveSubconversationIfNeeded(
        parentQualifiedID: QualifiedID,
        parentGroupID: MLSGroupID,
        subconversationType: SubgroupType,
        selfClientID: MLSClientID
    ) async throws {
        fatalError("not implemented")
    }

    // MARK: - New epoch

    func generateNewEpoch(groupID: MLSGroupID) async throws {
        fatalError("not implemented")
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

    // MARK: - Subconversation members

    func subconversationMembers(for subconversationGroupID: MLSGroupID) throws -> [MLSClientID] {
        fatalError("not implemented")
    }

}
