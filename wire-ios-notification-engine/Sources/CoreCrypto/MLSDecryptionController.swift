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

import Foundation
import WireDataModel
import CoreData
import CoreCryptoSwift

class MLSDecryptionController: MLSControllerProtocol {

    // MARK: - Properties

    private let coreCrypto: SafeCoreCryptoProtocol
    private weak var context: NSManagedObjectContext?

    // MARK: - Life cycle

    init(context: NSManagedObjectContext, coreCrypto: SafeCoreCryptoProtocol) {
        self.coreCrypto = coreCrypto
        self.context = context
    }

    // MARK: - Methods

    // TODO: Avoid this code duplication from `MLSController`

    public enum MLSMessageDecryptionError: Error {

        case failedToConvertMessageToBytes
        case failedToDecryptMessage

    }

    func decrypt(message: String, for groupID: MLSGroupID) throws -> MLSDecryptResult? {
        WireLogger.mls.info("decrypting message for group (\(groupID))")

        guard let messageBytes = message.base64EncodedBytes else {
            throw MLSMessageDecryptionError.failedToConvertMessageToBytes
        }

        do {
            let decryptedMessage = try coreCrypto.perform { try $0.decryptMessage(
                conversationId: groupID.bytes,
                payload: messageBytes
            )}

            if let commitDelay = decryptedMessage.commitDelay {
                return MLSDecryptResult.proposal(commitDelay)
            }

            if let message = decryptedMessage.message {
                return MLSDecryptResult.message(
                    message.data,
                    senderClientId(from: decryptedMessage)
                )
            }

            return nil

        } catch {
            WireLogger.mls.warn("failed to decrypt message for group (\(groupID)): \(String(describing: error))")
            throw MLSMessageDecryptionError.failedToDecryptMessage
        }
    }

    private func senderClientId(from message: DecryptedMessage) -> String? {
        guard let senderClientID = message.senderClientId else {
            return nil
        }

        return MLSClientID(data: senderClientID.data)?.clientID
    }

    // TODO: Avoid this code duplication from `MLSController`

    func scheduleCommitPendingProposals(groupID: MLSGroupID, at commitDate: Date) {
        guard let context = context else {
            return
        }

        context.performAndWait {
            WireLogger.mls.info("schedule to commit pending proposals in \(groupID) at \(commitDate)")
            let conversation = ZMConversation.fetch(with: groupID, in: context)
            conversation?.commitPendingProposalDate = commitDate
        }
    }
    
    // MARK: - Unavailable methods

    func commitPendingProposals() async throws {
        fatalError("not implemented")
    }

    func commitPendingProposals(in groupID: MLSGroupID) async throws {
        fatalError("not implemented")
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

    func encrypt(message: Bytes, for groupID: MLSGroupID) throws -> Bytes {
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

}
