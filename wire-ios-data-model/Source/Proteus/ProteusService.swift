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

/// A service that provides support for messaging via the Proteus
/// end-to-end-encryption protocol.

public final class ProteusService: ProteusServiceInterface {

    // MARK: - Properties

    private let coreCryptoProvider: CoreCryptoProviderProtocol
    private let logger = WireLogger.proteus

    private var coreCrypto: SafeCoreCryptoProtocol {
        get async throws {
            try await coreCryptoProvider.coreCrypto(requireMLS: false)
        }
    }

    // MARK: - Life cycle

    public init(coreCryptoProvider: CoreCryptoProviderProtocol) {
        self.coreCryptoProvider = coreCryptoProvider
    }

    // MARK: - proteusSessionFromPrekey

    enum ProteusSessionError: Error {
        case failedToEstablishSession
        case prekeyNotBase64Encoded
    }

    public func establishSession(
        id: ProteusSessionID,
        fromPrekey prekey: String
    ) async throws {
        logger.info("establishing session from prekey")

        guard let prekeyBytes = prekey.base64DecodedBytes else {
            throw ProteusSessionError.prekeyNotBase64Encoded
        }

        do {
            try await coreCrypto.perform { try $0.proteusSessionFromPrekey(
                sessionId: id.rawValue,
                prekey: prekeyBytes
            )}
        } catch {
            logger.error("failed to establish session from prekey: \(String(describing: error))")
            throw ProteusSessionError.failedToEstablishSession
        }
    }

    // MARK: - proteusSessionDelete

    enum DeleteSessionError: Error {
        case failedToDeleteSession
    }

    public func deleteSession(id: ProteusSessionID) async throws {
        logger.info("deleting session")

        do {
            try await coreCrypto.perform { try $0.proteusSessionDelete(sessionId: id.rawValue) }
        } catch {
            logger.error("failed to delete session: \(String(describing: error))")
            throw DeleteSessionError.failedToDeleteSession
        }
    }

    // MARK: - proteusSessionSave

    enum SaveSessionError: Error {
        case failedToSaveSession
    }

    // saving the session is managed internally by CC.
    // so there wouldn't be a need for this to be called.

    func saveSession(id: ProteusSessionID) async throws {
        do {
            try await coreCrypto.perform { try $0.proteusSessionSave(sessionId: id.rawValue) }
        } catch {
            // TODO: Log error
            throw SaveSessionError.failedToSaveSession
        }
    }

    // MARK: - proteusSessionExists

    public func sessionExists(id: ProteusSessionID) async -> Bool {
        logger.info("checking if session exists")

        do {
            return try await coreCrypto.perform { try $0.proteusSessionExists(sessionId: id.rawValue) }
        } catch {
            logger.error("failed to check if session exists \(String(describing: error))")
            return false
        }
    }

    // MARK: - proteusEncrypt

    enum EncryptionError: Error {
        case failedToEncryptData
        case failedToEncryptDataBatch
    }

    public func encrypt(
        data: Data,
        forSession id: ProteusSessionID
    ) async throws -> Data {
        logger.info("encrypting data")

        do {
            let encryptedBytes = try await coreCrypto.perform { try $0.proteusEncrypt(
                sessionId: id.rawValue,
                plaintext: data.bytes
            )}
            return encryptedBytes.data
        } catch {
            logger.error("failed to encrypt data: \(String(describing: error))")
            throw EncryptionError.failedToEncryptData
        }
    }

    // MARK: - proteusEncryptBatched

    public func encryptBatched(
        data: Data,
        forSessions sessions: [ProteusSessionID]
    ) async throws -> [String: Data] {
        logger.info("encrypting data batch")

        do {
            let encryptedBatch = try await coreCrypto.perform { try $0.proteusEncryptBatched(
                sessionId: sessions.map(\.rawValue),
                plaintext: data.bytes
            )}
            return encryptedBatch.mapValues(\.data)
        } catch {
            logger.error("failed to encrypt data batch: \(String(describing: error))")
            throw EncryptionError.failedToEncryptDataBatch
        }
    }

    // MARK: - proteusDecrypt

    public enum DecryptionError: Error, Equatable {

        case failedToDecryptData(ProteusError)
        case failedToEstablishSessionFromMessage(ProteusError)

        public var proteusError: ProteusError {
            switch self {
            case .failedToDecryptData(let proteusError):
                return proteusError

            case .failedToEstablishSessionFromMessage(let proteusError):
                return proteusError
            }
        }

    }

    public func decrypt(
        data: Data,
        forSession id: ProteusSessionID
    ) async throws -> (didCreateNewSession: Bool, decryptedData: Data) {
        logger.info("decrypting data")

        if await sessionExists(id: id) {
            logger.info("session exists, decrypting...")

            let decryptedBytes: [Byte] = try await coreCrypto.perform {
                do {
                    return try $0.proteusDecrypt(
                        sessionId: id.rawValue,
                        ciphertext: data.bytes
                    )
                } catch {
                    logger.error("failed to decrypt data: \(error.localizedDescription)")
                    throw DecryptionError.failedToDecryptData($0.lastProteusError)
                }
            }

            return (didCreateNewSession: false, decryptedData: decryptedBytes.data)

        } else {
            logger.info("session doesn't exist, creating one then decrypting message...")

            let decryptedBytes: [Byte] = try await coreCrypto.perform {
                do {
                    return try $0.proteusSessionFromMessage(
                        sessionId: id.rawValue,
                        envelope: data.bytes
                    )
                } catch {
                    logger.error("failed to establish session from message: \(String(describing: error))")
                    throw DecryptionError.failedToEstablishSessionFromMessage($0.lastProteusError)
                }
            }

            return (didCreateNewSession: true, decryptedData: decryptedBytes.data)
        }
    }

    // MARK: - proteusFingerprint

    enum FingerprintError: Error {
        case failedToGetLocalFingerprint
        case failedToGetRemoteFingerprint
        case failedToGetFingerprintFromPrekey
        case prekeyNotBase64Encoded
    }

    public func localFingerprint() async throws -> String {
        logger.info("fetching local fingerprint")

        do {
            return try await coreCrypto.perform { try $0.proteusFingerprint() }
        } catch {
            logger.error("failed to fetch local fingerprint: \(String(describing: error))")
            throw FingerprintError.failedToGetLocalFingerprint
        }
    }

    public func remoteFingerprint(forSession id: ProteusSessionID) async throws -> String {
        logger.info("fetching remote fingerprint")

        do {
            return try await coreCrypto.perform { try $0.proteusFingerprintRemote(sessionId: id.rawValue) }
        } catch {
            logger.error("failed to fetch remote fingerprint: \(String(describing: error))")
            throw FingerprintError.failedToGetRemoteFingerprint
        }
    }

    public func fingerprint(fromPrekey prekey: String) async throws -> String {
        logger.info("getting fingerprint from prekey")

        guard let prekeyBytes = prekey.base64DecodedBytes else {
            throw FingerprintError.prekeyNotBase64Encoded
        }

        do {
            return try await coreCrypto.perform { try $0.proteusFingerprintPrekeybundle(prekey: prekeyBytes) }
        } catch {
            logger.error("failed to get fingerprint from prekey: \(String(describing: error))")
            throw FingerprintError.failedToGetFingerprintFromPrekey
        }
    }
}

private extension CoreCryptoProtocol {

    var lastProteusError: ProteusError {
        return ProteusError(proteusCode: proteusLastErrorCode())
    }

}
