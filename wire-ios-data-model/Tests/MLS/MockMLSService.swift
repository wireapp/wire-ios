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

    // MARK: - Types

    enum MockError: Error {

        case unmockedMethodCalled

    }

    struct Calls {

        var uploadKeyPackagesIfNeeded: [Void] = []
        var createGroup = [MLSGroupID]()
        var conversationExists = [MLSGroupID]()
        var processWelcomeMessage = [String]()
        var enccrypt = [([Byte], MLSGroupID)]()
        var decrypt = [(String, MLSGroupID, SubgroupType?)]()
        var addMembersToConversation = [([MLSUser], MLSGroupID)]()
        var removeMembersFromConversation = [([MLSClientID], MLSGroupID)]()
        var commitPendingProposals: [Void] = []
        var commitPendingProposalsInGroup = [MLSGroupID]()
        var scheduleCommitPendingProposals: [(MLSGroupID, Date)] = []
        var registerPendingJoin = [MLSGroupID]()
        var performPendingJoins: [Void] = []
        var wipeGroup = [MLSGroupID]()
        var generateConferenceInfo = [(MLSGroupID, MLSGroupID)]()
        var joinGroup = [MLSGroupID]()
    }

    // MARK: - Properties

    var calls = Calls()

    // MARK: - Conference info

    typealias GenerateConferenceInfoMock = (MLSGroupID, MLSGroupID) throws -> MLSConferenceInfo

    var generateConferenceInfoMock: GenerateConferenceInfoMock?

    func generateConferenceInfo(
        parentGroupID: MLSGroupID,
        subconversationGroupID: MLSGroupID
    ) throws -> MLSConferenceInfo {
        calls.generateConferenceInfo.append((parentGroupID, subconversationGroupID))
        guard let mock = generateConferenceInfoMock else { throw MockError.unmockedMethodCalled }
        return try mock(parentGroupID, subconversationGroupID)
    }

    // MARK: - Key packages

    func uploadKeyPackagesIfNeeded() {
        calls.uploadKeyPackagesIfNeeded.append(())
    }

    // MARK: - Create group

    func createGroup(for groupID: MLSGroupID) throws {
        calls.createGroup.append(groupID)
    }

    // MARK: - Conversation exists

    typealias ConversationExistsMock = (MLSGroupID) -> Bool

    var conversationExistsMock: ConversationExistsMock?

    func conversationExists(groupID: MLSGroupID) -> Bool {
        calls.conversationExists.append(groupID)
        return conversationExistsMock?(groupID) ?? false
    }

    // MARK: - Process welcome message

    typealias ProcessWelcomeMessageMock = (String) throws -> MLSGroupID

    var processWelcomeMessageMock: ProcessWelcomeMessageMock?

    func processWelcomeMessage(welcomeMessage: String) throws -> MLSGroupID {
        calls.processWelcomeMessage.append(welcomeMessage)
        guard let mock = processWelcomeMessageMock else { throw MockError.unmockedMethodCalled }
        return try mock(welcomeMessage)
    }

    // MARK: - Encrypt

    typealias EncryptMock = ([Byte], MLSGroupID) throws -> [Byte]
    var encryptMock: EncryptMock?

    func encrypt(message: [Byte], for groupID: MLSGroupID) throws -> [Byte] {
        calls.enccrypt.append((message, groupID))
        guard let mock = encryptMock else { throw MockError.unmockedMethodCalled }
        return try mock(message, groupID)
    }

    // MARK: - Decrypt

    typealias DecryptMock = (String, MLSGroupID, SubgroupType?) throws -> MLSDecryptResult?

    var decryptMock: DecryptMock?

    func decrypt(message: String, for groupID: MLSGroupID, subconversationType: SubgroupType?) throws -> MLSDecryptResult? {
        calls.decrypt.append((message, groupID, subconversationType))
        guard let mock = decryptMock else { throw MockError.unmockedMethodCalled }
        return try mock(message, groupID, subconversationType)
    }

    // MARK: - Add members

    func addMembersToConversation(with users: [MLSUser], for groupID: MLSGroupID) throws {
        calls.addMembersToConversation.append((users, groupID))
    }

    // MARK: - Remove members

    typealias RemoveMembersMock = ([MLSClientID], MLSGroupID) throws -> Void

    var removeMembersMock: RemoveMembersMock?

    func removeMembersFromConversation(with clientIds: [MLSClientID], for groupID: MLSGroupID) throws {
        calls.removeMembersFromConversation.append((clientIds, groupID))
        guard let mock = removeMembersMock else { throw MockError.unmockedMethodCalled }
        try mock(clientIds, groupID)
    }

    // MARK: - Joining groups

    func registerPendingJoin(_ groupID: MLSGroupID) {
        calls.registerPendingJoin.append(groupID)
    }

    func performPendingJoins() {
        calls.performPendingJoins.append(())
    }

    // MARK: - Wiping group

    func wipeGroup(_ groupID: MLSGroupID) {
        calls.wipeGroup.append(groupID)
    }

    // MARK: - Pending Proposals

    func commitPendingProposals() {
        calls.commitPendingProposals.append(())
    }

    func commitPendingProposals(in groupID: MLSGroupID) async throws {
        calls.commitPendingProposalsInGroup.append(groupID)
    }

    func scheduleCommitPendingProposals(groupID: MLSGroupID, at commitDate: Date) {
        calls.scheduleCommitPendingProposals.append((groupID, commitDate))
    }

    func createOrJoinSubgroup(
        parentQualifiedID: QualifiedID,
        parentID: MLSGroupID
    ) async throws -> MLSGroupID {
        fatalError("not implemented")
    }

    func onConferenceInfoChange(parentGroupID: MLSGroupID, subConversationGroupID: MLSGroupID) -> AnyPublisher<MLSConferenceInfo, Never> {
        fatalError("not implemented")
    }

    func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
        fatalError("not implemented")
    }

    // MARK: - Self Group

    func createSelfGroup(for groupID: MLSGroupID) {
        fatalError("not implemented")
    }

    func joinGroup(with groupID: MLSGroupID) async throws {
        calls.joinGroup.append(groupID)
    }

    func joinNewGroup(with groupID: MLSGroupID) async throws {
        fatalError("not implemented")
    }

    // MARK: - Subconversation

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

    // MARK: - Subconversation Members

    func subconversationMembers(for subconversationGroupID: MLSGroupID) throws -> [MLSClientID] {
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

    typealias FetchAndRepairGroupMock = (MLSGroupID) -> Void
    var fetchAndRepairGroupMock: FetchAndRepairGroupMock?

    func fetchAndRepairGroup(with groupID: MLSGroupID) async {
        guard let mock = fetchAndRepairGroupMock else {
            return
        }
        mock(groupID)
    }

    // MARK: - Migration

    typealias StartProteusToMLSMigrationMock = () -> Void
    var startProteusToMLSMigrationMock: StartProteusToMLSMigrationMock?

    func startProteusToMLSMigration() {
        guard let mock = startProteusToMLSMigrationMock else {
            return
        }
        mock()
    }
}
