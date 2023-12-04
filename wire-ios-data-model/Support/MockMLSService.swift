//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

import WireDataModel
import Combine

public final class MockMLSService: MLSServiceInterface {

    // MARK: - Types

    enum MockError: Error {
        case unmockedMethodCalled
    }

    public struct Calls {

        public var uploadKeyPackagesIfNeeded: [Void] = []
        public var createSelfGroup = [MLSGroupID]()
        public var joinGroup = [MLSGroupID]()
        public var createGroup = [MLSGroupID]()
        public var conversationExists = [MLSGroupID]()
        public var processWelcomeMessage = [String]()
        public var enccrypt = [([Byte], MLSGroupID)]()
        public var decrypt = [(String, MLSGroupID, SubgroupType?)]()
        public var addMembersToConversation = [([MLSUser], MLSGroupID)]()
        public var removeMembersFromConversation = [([MLSClientID], MLSGroupID)]()
        public var commitPendingProposals: [Void] = []
        public var commitPendingProposalsInGroup = [MLSGroupID]()
        public var scheduleCommitPendingProposals: [(MLSGroupID, Date)] = []
        public var registerPendingJoin = [MLSGroupID]()
        public var performPendingJoins: [Void] = []
        public var wipeGroup = [MLSGroupID]()
        public var generateConferenceInfo = [(MLSGroupID, MLSGroupID)]()
        public var subconversationMembersForSubconversationGroupID = [MLSGroupID]()

    }

    // MARK: - Properties

    public var calls = Calls()

    // MARK: - Life Cycle

    public init() {}

    // MARK: - Conference info

    public typealias GenerateConferenceInfoMock = (MLSGroupID, MLSGroupID) throws -> MLSConferenceInfo

    public var generateConferenceInfoMock: GenerateConferenceInfoMock?

    public func generateConferenceInfo(
        parentGroupID: MLSGroupID,
        subconversationGroupID: MLSGroupID
    ) throws -> MLSConferenceInfo {
        calls.generateConferenceInfo.append((parentGroupID, subconversationGroupID))
        guard let mock = generateConferenceInfoMock else { throw MockError.unmockedMethodCalled }
        return try mock(parentGroupID, subconversationGroupID)
    }

    // MARK: - Key packages

    public func uploadKeyPackagesIfNeeded() {
        calls.uploadKeyPackagesIfNeeded.append(())
    }

    // MARK: - Create group

    public func createGroup(for groupID: MLSGroupID) throws {
        calls.createGroup.append(groupID)
    }

    // MARK: - Conversation exists

    public typealias ConversationExistsMock = (MLSGroupID) -> Bool

    public var conversationExistsMock: ConversationExistsMock?

    public func conversationExists(groupID: MLSGroupID) -> Bool {
        calls.conversationExists.append(groupID)
        return conversationExistsMock?(groupID) ?? false
    }

    // MARK: - Process welcome message

    public typealias ProcessWelcomeMessageMock = (String) throws -> MLSGroupID

    public var processWelcomeMessageMock: ProcessWelcomeMessageMock?

    public func processWelcomeMessage(welcomeMessage: String) throws -> MLSGroupID {
        calls.processWelcomeMessage.append(welcomeMessage)
        guard let mock = processWelcomeMessageMock else { throw MockError.unmockedMethodCalled }
        return try mock(welcomeMessage)
    }

    // MARK: - Encrypt

    typealias EncryptMock = ([Byte], MLSGroupID) throws -> [Byte]
    var encryptMock: EncryptMock?

    public func encrypt(message: [Byte], for groupID: MLSGroupID) throws -> [Byte] {
        calls.enccrypt.append((message, groupID))
        guard let mock = encryptMock else { throw MockError.unmockedMethodCalled }
        return try mock(message, groupID)
    }

    // MARK: - Decrypt

    public typealias DecryptMock = (String, MLSGroupID, SubgroupType?) throws -> MLSDecryptResult?

    public var decryptMock: DecryptMock?

    public func decrypt(message: String, for groupID: MLSGroupID, subconversationType: SubgroupType?) throws -> MLSDecryptResult? {
        calls.decrypt.append((message, groupID, subconversationType))
        guard let mock = decryptMock else { throw MockError.unmockedMethodCalled }
        return try mock(message, groupID, subconversationType)
    }

    // MARK: - Add members

    public func addMembersToConversation(with users: [MLSUser], for groupID: MLSGroupID) throws {
        calls.addMembersToConversation.append((users, groupID))
    }

    // MARK: - Remove members

    public typealias RemoveMembersMock = ([MLSClientID], MLSGroupID) throws -> Void

    public var removeMembersMock: RemoveMembersMock?

    public func removeMembersFromConversation(with clientIds: [MLSClientID], for groupID: MLSGroupID) throws {
        calls.removeMembersFromConversation.append((clientIds, groupID))
        guard let mock = removeMembersMock else { throw MockError.unmockedMethodCalled }
        try mock(clientIds, groupID)
    }

    // MARK: - Joining groups

    public func registerPendingJoin(_ groupID: MLSGroupID) {
        calls.registerPendingJoin.append(groupID)
    }

    public func performPendingJoins() {
        calls.performPendingJoins.append(())
    }

    // MARK: - Wiping group

    public func wipeGroup(_ groupID: MLSGroupID) {
        calls.wipeGroup.append(groupID)
    }

    // MARK: - Pending Proposals

    public func commitPendingProposals() {
        calls.commitPendingProposals.append(())
    }

    public func commitPendingProposals(in groupID: MLSGroupID) async throws {
        calls.commitPendingProposalsInGroup.append(groupID)
    }

    func scheduleCommitPendingProposals(groupID: MLSGroupID, at commitDate: Date) {
        calls.scheduleCommitPendingProposals.append((groupID, commitDate))
    }

    public var mockCreateOrJoinSubgroup: ((QualifiedID, MLSGroupID) -> MLSGroupID)?

    public func createOrJoinSubgroup(
        parentQualifiedID: QualifiedID,
        parentID: MLSGroupID
    ) async throws -> MLSGroupID {
        guard let mock = mockCreateOrJoinSubgroup else {
            throw MockError.unmockedMethodCalled
        }

        return mock(parentQualifiedID, parentID)
    }

    public var mockOnConferenceInfoChange: ((MLSGroupID, MLSGroupID) -> AnyPublisher<MLSConferenceInfo, Never>)?

    public func onConferenceInfoChange(parentGroupID: MLSGroupID, subConversationGroupID: MLSGroupID) -> AnyPublisher<MLSConferenceInfo, Never> {
        guard let mock = mockOnConferenceInfoChange else {
            fatalError("missing mock for `onConferenceInfoChange`")
        }

        return mock(parentGroupID, subConversationGroupID)
    }

    public func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
        fatalError("not implemented")
    }

    // MARK: - Self Group

    public var mockCreateSelfGroup: ((MLSGroupID) -> Void)?
    public func createSelfGroup(for groupID: MLSGroupID) {
        calls.createSelfGroup.append(groupID)
        mockCreateSelfGroup?(groupID)
    }

    public var mockJoinGroup: ((MLSGroupID) throws -> Void)?
    public func joinGroup(with groupID: MLSGroupID) async throws {
        calls.joinGroup.append(groupID)
        try mockJoinGroup?(groupID)
    }

    public func joinNewGroup(with groupID: MLSGroupID) async throws {
        fatalError("not implemented")
    }

    // MARK: - Subconversation

    public var mockLeaveSubconversation: ((QualifiedID, MLSGroupID, SubgroupType) throws -> Void)?

    public func leaveSubconversation(
        parentQualifiedID: QualifiedID,
        parentGroupID: MLSGroupID,
        subconversationType: SubgroupType
    ) async throws {
        guard let mock = mockLeaveSubconversation else {
            throw MockError.unmockedMethodCalled
        }

        try mock(parentQualifiedID, parentGroupID, subconversationType)
    }

    public var mockLeaveSubconversationIfNeeded: ((QualifiedID, MLSGroupID, SubgroupType, MLSClientID) throws -> Void)?

    public func leaveSubconversationIfNeeded(
        parentQualifiedID: QualifiedID,
        parentGroupID: MLSGroupID,
        subconversationType: SubgroupType,
        selfClientID: MLSClientID
    ) async throws {
        guard let mock = mockLeaveSubconversationIfNeeded else {
            throw MockError.unmockedMethodCalled
        }

        try mock(parentQualifiedID, parentGroupID, subconversationType, selfClientID)
    }

    // MARK: - New epoch

    public var mockGenerateNewEpoch: ((MLSGroupID) -> Void)?

    public func generateNewEpoch(groupID: MLSGroupID) async throws {
        guard let mock = mockGenerateNewEpoch else { throw MockError.unmockedMethodCalled }

        return mock(groupID)
    }

    // MARK: - Subconversation Members

    public var mockSubconversationMembers: ((MLSGroupID) -> [MLSClientID])?

    public func subconversationMembers(for subconversationGroupID: MLSGroupID) throws -> [MLSClientID] {
        calls.subconversationMembersForSubconversationGroupID.append(subconversationGroupID)
        guard let mock = mockSubconversationMembers else { throw MockError.unmockedMethodCalled }

        return mock(subconversationGroupID)
    }

    // MARK: - Out of sync

    typealias RepairOutOfSyncConversationsMock = () -> Void
    var repairOutOfSyncConversationsMock: RepairOutOfSyncConversationsMock?

    public func repairOutOfSyncConversations() {
        guard let mock = repairOutOfSyncConversationsMock else {
            return
        }
        mock()
    }

    typealias FetchAndRepairGroupMock = (MLSGroupID) -> Void
    var fetchAndRepairGroupMock: FetchAndRepairGroupMock?

    public func fetchAndRepairGroup(with groupID: MLSGroupID) async {
        guard let mock = fetchAndRepairGroupMock else {
            return
        }
        mock(groupID)
    }
}
