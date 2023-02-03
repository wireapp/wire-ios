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

class MockMLSController: MLSControllerProtocol {

    var mockDecryptResult: MLSDecryptResult?
    var mockDecryptionError: MLSController.MLSMessageDecryptionError?
    var calls = Calls()

    struct Calls {
        var decrypt: [(String, MLSGroupID)] = []
        var commitPendingProposals: [Void] = []
        var commitPendingProposalsInGroup: [MLSGroupID] = []
        var scheduleCommitPendingProposals: [(MLSGroupID, Date)] = []
        var wipeGroup = [MLSGroupID]()
    }

    func decrypt(message: String, for groupID: MLSGroupID) throws -> MLSDecryptResult? {
        calls.decrypt.append((message, groupID))

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

    func encrypt(message: Bytes, for groupID: MLSGroupID) throws -> Bytes {
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

    func scheduleCommitPendingProposals(groupID: MLSGroupID, at commitDate: Date) {
        calls.scheduleCommitPendingProposals.append((groupID, commitDate))
    }
}
