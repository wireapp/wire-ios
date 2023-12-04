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

import Combine
import WireDataModel

public struct MockMLSServiceX: MLSServiceInterface {

    public func uploadKeyPackagesIfNeeded() {
        fatalError("TODO")
    }

    public func createSelfGroup(for groupID: MLSGroupID) {
        fatalError("TODO")
    }

    public func joinGroup(with groupID: MLSGroupID) async throws {
        fatalError("TODO")
    }

    public func joinNewGroup(with groupID: MLSGroupID) async throws {
        fatalError("TODO")
    }

    public func createGroup(for groupID: MLSGroupID) throws {
        fatalError("TODO")
    }

    public func conversationExists(groupID: MLSGroupID) -> Bool {
        fatalError("TODO")
    }

    public func processWelcomeMessage(welcomeMessage: String) throws -> MLSGroupID {
        fatalError("TODO")
    }

    public func addMembersToConversation(with users: [MLSUser], for groupID: MLSGroupID) async throws {
        fatalError("TODO")
    }

    public func removeMembersFromConversation(with clientIds: [MLSClientID], for groupID: MLSGroupID) async throws {
        fatalError("TODO")
    }

    public func registerPendingJoin(_ group: MLSGroupID) {
        fatalError("TODO")
    }

    public func performPendingJoins() {
        fatalError("TODO")
    }

    public func wipeGroup(_ groupID: MLSGroupID) {
        fatalError("TODO")
    }

    public func commitPendingProposals() async throws {
        fatalError("TODO")
    }

    public func commitPendingProposals(in groupID: MLSGroupID) async throws {
        fatalError("TODO")
    }

    public func createOrJoinSubgroup(parentQualifiedID: QualifiedID, parentID: MLSGroupID) async throws -> MLSGroupID {
        fatalError("TODO")
    }

    public func generateConferenceInfo(parentGroupID: MLSGroupID, subconversationGroupID: MLSGroupID) throws -> MLSConferenceInfo {
        fatalError("TODO")
    }

    public func onConferenceInfoChange(parentGroupID: MLSGroupID, subConversationGroupID: MLSGroupID) -> AnyPublisher<MLSConferenceInfo, Never> {
        fatalError("TODO")
    }

    public func leaveSubconversationIfNeeded(parentQualifiedID: QualifiedID, parentGroupID: MLSGroupID, subconversationType: SubgroupType, selfClientID: MLSClientID) async throws {
        fatalError("TODO")
    }

    public func leaveSubconversation(parentQualifiedID: QualifiedID, parentGroupID: MLSGroupID, subconversationType: SubgroupType) async throws {
        fatalError("TODO")
    }

    public func generateNewEpoch(groupID: MLSGroupID) async throws {
        fatalError("TODO")
    }

    public func subconversationMembers(for subconversationGroupID: MLSGroupID) throws -> [MLSClientID] {
        fatalError("TODO")
    }

    public func repairOutOfSyncConversations() {
        fatalError("TODO")
    }

    public func fetchAndRepairGroup(with groupID: MLSGroupID) async {
        fatalError("TODO")
    }

    public func encrypt(message: [WireUtilities.Byte], for groupID: MLSGroupID) throws -> [WireUtilities.Byte] {
        fatalError("TODO")
    }

    public func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
        fatalError("TODO")
    }

    public func decrypt(message: String, for groupID: MLSGroupID, subconversationType: SubgroupType?) throws -> MLSDecryptResult? {
        fatalError("TODO")
    }
}
