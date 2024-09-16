//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
            try await coreCryptoProvider.coreCrypto()
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

        guard let prekeyData = prekey.base64DecodedData else {
            throw ProteusSessionError.prekeyNotBase64Encoded
        }

        do {
            try await coreCrypto.perform { try await $0.proteusSessionFromPrekey(
                sessionId: id.rawValue,
                prekey: prekeyData
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
            try await coreCrypto.perform { try await $0.proteusSessionDelete(sessionId: id.rawValue) }
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
            try await coreCrypto.perform { try await $0.proteusSessionSave(sessionId: id.rawValue) }
        } catch {
            // swiftlint:disable todo_requires_jira_link
            // TODO: Log error
            // swiftlint:enable todo_requires_jira_link
            throw SaveSessionError.failedToSaveSession
        }
    }

    // MARK: - proteusSessionExists

    public func sessionExists(id: ProteusSessionID) async -> Bool {
        logger.info("checking if session exists")

        do {
            return try await coreCrypto.perform { try await $0.proteusSessionExists(sessionId: id.rawValue) }
        } catch {
            logger.error("failed to check if session exists \(String(describing: error))")
            return false
        }
    }

    // MARK: - proteusEncrypt

    enum EncryptionError: Error, Equatable {
        case failedToEncryptData(Error)
        case failedToEncryptDataBatch(Error)

        static func == (lhs: ProteusService.EncryptionError, rhs: ProteusService.EncryptionError) -> Bool {
            switch (lhs, rhs) {
            case (let failedToEncryptData(lhsError), let failedToEncryptData(rhsError)):
                return lhsError as NSError == rhsError as NSError
            case (let failedToEncryptDataBatch(lhsError), let failedToEncryptDataBatch(rhsError)):
                return lhsError as NSError == rhsError as NSError

            default:
                return false
            }
        }
    }

    public func encrypt(
        data: Data,
        forSession id: ProteusSessionID
    ) async throws -> Data {
        logger.info("encrypting data")

        do {
            let encryptedData = try await coreCrypto.unsafePerform {
                try await $0.proteusEncrypt(
                    sessionId: id.rawValue,
                    plaintext: data
                )
            }
            return encryptedData
        } catch {
            throw EncryptionError.failedToEncryptData(error)
        }
    }

    // MARK: - proteusEncryptBatched

    public func encryptBatched(
        data: Data,
        forSessions sessions: [ProteusSessionID]
    ) async throws -> [String: Data] {
        logger.info("encrypting data batch")

        do {
            let encryptedBatch = try await coreCrypto.perform {
                try await $0.proteusEncryptBatched(
                    sessions: sessions.map(\.rawValue),
                    plaintext: data
                )
            }
            return encryptedBatch
        } catch {
            throw EncryptionError.failedToEncryptDataBatch(error)
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

            let decryptedData: Data = try await coreCrypto.perform {
                do {
                    return try await $0.proteusDecrypt(
                        sessionId: id.rawValue,
                        ciphertext: data
                    )
                } catch {
                    throw DecryptionError.failedToDecryptData($0.lastProteusError)
                }
            }

            return (didCreateNewSession: false, decryptedData: decryptedData)

        } else {
            logger.info("session doesn't exist, creating one then decrypting message...")

            let decryptedData: Data = try await coreCrypto.perform {
                do {
                    return try await $0.proteusSessionFromMessage(
                        sessionId: id.rawValue,
                        envelope: data
                    )
                } catch {
                    throw DecryptionError.failedToEstablishSessionFromMessage($0.lastProteusError)
                }
            }

            return (didCreateNewSession: true, decryptedData: decryptedData)
        }
    }

    // MARK: - proteusNewPrekey

    enum PrekeyError: Error {
        case failedToGeneratePrekey
        case prekeyCountTooLow
        case failedToGetLastPrekey
    }

    public func generatePrekey(id: UInt16) async throws -> String {
        do {
            return try await coreCrypto.perform { try await $0.proteusNewPrekey(prekeyId: id).base64EncodedString() }
        } catch {
            throw PrekeyError.failedToGeneratePrekey
        }
    }

    public func lastPrekey() async throws -> String {
        logger.info("getting last resort prekey")
        do {
            return try await coreCrypto.perform { try await $0.proteusLastResortPrekey().base64EncodedString() }
        } catch {
            logger.error("failed to get last resort prekey: \(String(describing: error))")
            throw PrekeyError.failedToGetLastPrekey
        }
    }

    public var lastPrekeyID: UInt16 {
        get async {
            let lastPrekeyID = try? await coreCrypto.perform { try $0.proteusLastResortPrekeyId() }
            return lastPrekeyID ?? UInt16.max
        }
    }

    public func generatePrekeys(start: UInt16 = 0, count: UInt16 = 0) async throws -> [IdPrekeyTuple] {
        guard count > 0 else {
            throw PrekeyError.prekeyCountTooLow
        }

        logger.info("generate \(count) prekeys")
        let range = await prekeysRange(count, start: start)
        let prekeys = try await generatePrekeys(range)

        guard prekeys.count > 0 else {
            throw PrekeyError.failedToGeneratePrekey
        }

        return prekeys
    }

    private func generatePrekeys(_ range: CountableRange<UInt16>) async throws -> [IdPrekeyTuple] {
        var prekeys = [IdPrekeyTuple]()
        for id in range {
            let prekey = try await generatePrekey(id: id)
            prekeys.append((id: id, prekey: prekey))
        }
        return prekeys
    }

    private func prekeysRange(_ count: UInt16, start: UInt16) async -> CountableRange<UInt16> {
        let keyId = await lastPrekeyID
        if start + count > keyId {
            return 0 ..< count
        }
        return start ..< (start + count)
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
            return try await coreCrypto.perform { try await $0.proteusFingerprint() }
        } catch {
            logger.error("failed to fetch local fingerprint: \(String(describing: error))")
            throw FingerprintError.failedToGetLocalFingerprint
        }
    }

    public func remoteFingerprint(forSession id: ProteusSessionID) async throws -> String {
        logger.info("fetching remote fingerprint")

        do {
            return try await coreCrypto.perform { try await $0.proteusFingerprintRemote(sessionId: id.rawValue) }
        } catch {
            logger.error("failed to fetch remote fingerprint: \(String(describing: error))")
            throw FingerprintError.failedToGetRemoteFingerprint
        }
    }

    public func fingerprint(fromPrekey prekey: String) async throws -> String {
        logger.info("getting fingerprint from prekey")

        guard let prekeyData = prekey.base64DecodedData else {
            throw FingerprintError.prekeyNotBase64Encoded
        }

        do {
            return try await coreCrypto.perform { try $0.proteusFingerprintPrekeybundle(prekey: prekeyData) }
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
