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
import WireSystem

// sourcery: AutoMockable
public protocol MLSDecryptionServiceInterface {

    func onEpochChanged() -> AnyPublisher<MLSGroupID, Never>

    func decrypt(
        message: String,
        for groupID: MLSGroupID,
        subconversationType: SubgroupType?
    ) async throws -> MLSDecryptResult?

}

public enum MLSDecryptResult: Equatable {

    case message(_ messageData: Data, _ senderClientID: String?)
    case proposal(_ commitDelay: UInt64)

}

public final class MLSDecryptionService: MLSDecryptionServiceInterface {

    // MARK: - Properties

    private let coreCryptoProvider: CoreCryptoProviderProtocol
    private weak var context: NSManagedObjectContext?
    private let subconverationGroupIDRepository: SubconversationGroupIDRepositoryInterface

    private let onEpochChangedSubject = PassthroughSubject<MLSGroupID, Never>()

    public func onEpochChanged() -> AnyPublisher<MLSGroupID, Never> {
        return onEpochChangedSubject.eraseToAnyPublisher()
    }

    // MARK: - Life cycle

    public init(
        context: NSManagedObjectContext,
        coreCryptoProvider: CoreCryptoProviderProtocol,
        subconversationGroupIDRepository: SubconversationGroupIDRepositoryInterface = SubconversationGroupIDRepository()
    ) {
        self.coreCryptoProvider = coreCryptoProvider
        self.context = context
        self.subconverationGroupIDRepository = subconversationGroupIDRepository
    }

    var coreCrypto: SafeCoreCryptoProtocol {
        get async throws {
            return try await coreCryptoProvider.coreCrypto(requireMLS: true)
        }
    }

    // MARK: - Message decryption

    public enum MLSMessageDecryptionError: Error {

        case failedToConvertMessageToBytes
        case failedToDecryptMessage
        case wrongEpoch

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
    ) async throws -> MLSDecryptResult? {
        WireLogger.mls.debug("decrypting message for group (\(groupID.safeForLoggingDescription)) and subconversation type (\(String(describing: subconversationType)))")

        guard let messageData = message.base64DecodedData else {
            throw MLSMessageDecryptionError.failedToConvertMessageToBytes
        }

        var groupID = groupID
        var debugInfo = "parentID: \(groupID)"
        if
            let type = subconversationType,
            let subconversationGroupID = await subconverationGroupIDRepository.fetchSubconversationGroupID(
                forType: type,
                parentGroupID: groupID
            )
        {
            groupID = subconversationGroupID
            debugInfo.append("; subconversationGroupID: \(subconversationGroupID)")
        }

        do {
            let decryptedMessage = try await coreCrypto.perform {
                try await $0.decryptMessage(
                    conversationId: groupID.data,
                    payload: messageData
                )
            }

            if decryptedMessage.hasEpochChanged {
                onEpochChangedSubject.send(groupID)
            }

            if let commitDelay = decryptedMessage.commitDelay {
                return MLSDecryptResult.proposal(commitDelay)
            }

            if let message = decryptedMessage.message {
                return MLSDecryptResult.message(
                    message,
                    senderClientId(from: decryptedMessage)
                )
            }

            return nil
        } catch {
            WireLogger.mls.error("failed to decrypt message for group (\(groupID.safeForLoggingDescription)) and subconversation type (\(String(describing: subconversationType))): \(String(describing: error)) | \(debugInfo)")

            if case CryptoError.WrongEpoch(message: _) = error {
                throw MLSMessageDecryptionError.wrongEpoch
            } else {
                throw MLSMessageDecryptionError.failedToDecryptMessage
            }
        }
    }

    private func senderClientId(from message: DecryptedMessage) -> String? {
        guard let senderClientID = message.senderClientId else { return nil }
        return MLSClientID(data: senderClientID)?.clientID
    }
}
