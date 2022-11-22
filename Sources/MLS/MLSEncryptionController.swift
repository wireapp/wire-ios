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

class MLSEncryptionController: MLSControllerProtocol {

    private let coreCrypto: CoreCryptoProtocol

    init(coreCrypto: CoreCryptoProtocol) {
        self.coreCrypto = coreCrypto
    }

    func encrypt(message: Bytes, for groupID: MLSGroupID) throws -> WireDataModel.Bytes {
        return try coreCrypto.wire_encryptMessage(conversationId: groupID.bytes, message: message)
    }

    func commitPendingProposals(in groupID: MLSGroupID) async throws {
        // no op
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

    func decrypt(message: String, for groupID: MLSGroupID) throws -> MLSDecryptResult? {
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

    func performPendingJoins() {
        fatalError("not implemented")
    }

    func wipeGroup(_ groupID: MLSGroupID) {
        fatalError("not implemented")
    }

    func commitPendingProposals() async throws {
        fatalError("not implemented")
    }

    func scheduleCommitPendingProposals(groupID: MLSGroupID, at commitDate: Date) {
        fatalError("not implemented")
    }

}
