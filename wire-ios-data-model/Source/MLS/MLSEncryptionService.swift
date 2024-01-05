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

// sourcery: AutoMockable
public protocol MLSEncryptionServiceInterface {

    func encrypt(
        message: Data,
        for groupID: MLSGroupID
    ) async throws -> Data

}

public final class MLSEncryptionService: MLSEncryptionServiceInterface {

    // MARK: - Properties

    private let coreCryptoProvider: CoreCryptoProviderProtocol

    // MARK: - Life cycle

    public init(coreCryptoProvider: CoreCryptoProviderProtocol) {
        self.coreCryptoProvider = coreCryptoProvider
    }

    var coreCrypto: SafeCoreCryptoProtocol {
        get async throws {
            try await coreCryptoProvider.coreCrypto(requireMLS: true)
        }
    }
    // MARK: - Message encryption

    public enum MLSMessageEncryptionError: Error {

        case failedToEncryptMessage

    }

    /// Encrypts a message for the given group.
    ///
    /// - Parameters:
    ///   - message: data representing the plaintext message
    ///   - groupID: the id of the MLS group in which to encrypt
    ///
    /// - Throws:
    ///   `MLSMessageEncryptionError` if the message couldn't be encrypted
    ///
    /// - Returns:
    ///   A byte array representing the ciphertext.

    public func encrypt(
        message: Data,
        for groupID: MLSGroupID
    ) async throws -> Data {
        do {
            WireLogger.mls.debug("encrypting message (\(message.count) bytes) for group (\(groupID))")
            return try await coreCrypto.perform { try await $0.encryptMessage(conversationId: groupID.data, message: message) }
        } catch let error {
            WireLogger.mls.error("failed to encrypt message for group (\(groupID)): \(String(describing: error))")
            throw MLSMessageEncryptionError.failedToEncryptMessage
        }
    }

}
