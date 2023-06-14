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
import WireCoreCrypto
import Combine

// sourcery: AutoMockable
public protocol MLSDecryptionServiceInterface {

    func onEpochChanged() -> AnyPublisher<MLSGroupID, Never>

    func decrypt(
        message: String,
        for groupID: MLSGroupID,
        subconversationType: SubgroupType?
    ) throws -> MLSDecryptResult?

}

public enum MLSDecryptResult: Equatable {

    case message(_ messageData: Data, _ senderClientID: String?)
    case proposal(_ commitDelay: UInt64)

}

public final class MLSDecryptionService: MLSDecryptionServiceInterface {

    // MARK: - Properties

    private let coreCrypto: SafeCoreCryptoProtocol
    private weak var context: NSManagedObjectContext?
    private let subconverationGroupIDRepository: SubconversationGroupIDRepositoryInterface

    private let onEpochChangedSubject = PassthroughSubject<MLSGroupID, Never>()

    public func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
        return onEpochChangedSubject.eraseToAnyPublisher()
    }

    // MARK: - Life cycle

    public init(
        context: NSManagedObjectContext,
        coreCrypto: SafeCoreCryptoProtocol,
        subconversationGroupIDRepository: SubconversationGroupIDRepositoryInterface = SubconversationGroupIDRepository()
    ) {
        self.coreCrypto = coreCrypto
        self.context = context
        self.subconverationGroupIDRepository = subconversationGroupIDRepository
    }

    // MARK: - Message decryption

    public enum MLSMessageDecryptionError: Error {

        case failedToConvertMessageToBytes
        case failedToDecryptMessage

    }

    /// Decrypts an MLS message for the given group
    ///
    /// - Parameters:
    ///   - message: a base64 encoded encrypted message
    ///   - groupID: the id of the MLS group
    ///   - subconversationType: the type of subconversation (if it exists)  to which this message belongs
    ///
    /// - Throws: `MLSMessageDecryptionError` if the message could not be decrypted.
    ///
    /// - Returns:
    ///   The data representing the decrypted message bytes.
    ///   May be nil if the message was a handshake message, in which case it is safe to ignore.

    public func decrypt(
        message: String,
        for groupID: MLSGroupID,
        subconversationType: SubgroupType?
    ) throws -> MLSDecryptResult? {
        WireLogger.mls.debug("decrypting message for group (\(groupID)) and subconversation type (\(String(describing: subconversationType))")

        guard let messageBytes = message.base64DecodedBytes else {
            throw MLSMessageDecryptionError.failedToConvertMessageToBytes
        }

        var groupID = groupID

        if
            let type = subconversationType,
            let subconversationGroupID = subconverationGroupIDRepository.fetchSubconversationGroupID(
                forType: type,
                parentGroupID: groupID
            )
        {
            groupID = subconversationGroupID
        }

        do {
            let decryptedMessage = try coreCrypto.perform { try $0.decryptMessage(
                conversationId: groupID.bytes,
                payload: messageBytes
            ) }

            if decryptedMessage.hasEpochChanged {
                onEpochChangedSubject.send(groupID)
            }

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
            WireLogger.mls.error("failed to decrypt message for group (\(groupID)) and subconversation type (\(String(describing: subconversationType)): \(String(describing: error))")
            throw MLSMessageDecryptionError.failedToDecryptMessage
        }
    }

    private func senderClientId(from message: DecryptedMessage) -> String? {
        guard let senderClientID = message.senderClientId else { return nil }
        return MLSClientID(data: senderClientID.data)?.clientID
    }

}
