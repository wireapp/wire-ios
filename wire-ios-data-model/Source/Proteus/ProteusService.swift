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
import CoreCryptoSwift

/// A service that provides support for messaging via the Proteus
/// end-to-end-encryption protocol.

public final class ProteusService: ProteusServiceInterface {

    // MARK: - Properties

    private let coreCrypto: SafeCoreCryptoProtocol
    private let logger = WireLogger.proteus

    // MARK: - Life cycle

    public init(coreCrypto: SafeCoreCryptoProtocol) throws {
        self.coreCrypto = coreCrypto
        // this is fine not to lock for initialization
        try coreCrypto.perform { try $0.proteusInit() }
    }

    // MARK: - proteusSessionFromPrekey

    enum ProteusSessionError: Error {
        case failedToEstablishSession
        case prekeyNotBase64Encoded
        case failedToEstablishSessionFromMessage
        case messageNotBase64Encoded
    }

    public func establishSession(id: String, fromPrekey prekey: String) throws {
        logger.info("establishing session from prekey")

        guard let prekeyBytes = prekey.base64EncodedBytes else {
            throw ProteusSessionError.prekeyNotBase64Encoded
        }

        do {
            try coreCrypto.perform { try $0.proteusSessionFromPrekey(
                sessionId: id,
                prekey: prekeyBytes
            ) }
        } catch {
            logger.error("failed to establish session from prekey: \(String(describing: error))")
            throw ProteusSessionError.failedToEstablishSession
        }
    }

    // MARK: - proteusSessionFromMessage

    public func establishSession(id: String, fromMessage message: String) throws -> Data {
        logger.info("establishing session from message")

        guard let messageBytes = message.base64EncodedBytes else {
            throw ProteusSessionError.messageNotBase64Encoded
        }

        do {
            let decryptedBytes = try coreCrypto.perform { try $0.proteusSessionFromMessage(
                sessionId: id,
                envelope: messageBytes
            ) }
            return decryptedBytes.data
        } catch {
            logger.error("failed to establish session from message: \(String(describing: error))")
            throw ProteusSessionError.failedToEstablishSessionFromMessage
        }
    }

    // MARK: - proteusSessionDelete

    enum DeleteSessionError: Error {
        case failedToDeleteSession
    }

    public func deleteSession(id: String) throws {
        logger.info("deleting session")

        do {
            try coreCrypto.perform { try $0.proteusSessionDelete(sessionId: id) }
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

    func saveSession(id: String) throws {
        do {
            try coreCrypto.perform { try $0.proteusSessionSave(sessionId: id) }
        } catch {
            // TODO: Log error
            throw SaveSessionError.failedToSaveSession
        }
    }

    // MARK: - proteusSessionExists

    public func sessionExists(id: String) -> Bool {
        logger.info("checking if session exists")

        do {
            return try coreCrypto.perform { try $0.proteusSessionExists(sessionId: id) }
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

    public func encrypt(data: Data, forSession id: String) throws -> Data {
        logger.info("encrypting data")

        do {
            let encryptedBytes = try coreCrypto.perform { try $0.proteusEncrypt(
                sessionId: id,
                plaintext: data.bytes
            ) }
            return encryptedBytes.data
        } catch {
            logger.error("failed to encrypt data: \(String(describing: error))")
            throw EncryptionError.failedToEncryptData
        }
    }

    // MARK: - proteusEncryptBatched

    public func encryptBatched(data: Data, forSessions sessions: [String]) throws -> [String: Data] {
        logger.info("encrypting data batch")

        do {
            let encryptedBatch = try coreCrypto.perform { try $0.proteusEncryptBatched(
                sessionId: sessions,
                plaintext: data.bytes
            ) }
            return encryptedBatch.mapValues(\Bytes.data)
        } catch {
            logger.error("failed to encrypt data batch: \(String(describing: error))")
            throw EncryptionError.failedToEncryptDataBatch
        }
    }

    // MARK: - proteusDecrypt

    enum DecryptionError: Error {
        case failedToDecryptData
    }

    public func decrypt(data: Data, forSession id: String) throws -> Data {
        logger.info("decrypting data")

        do {
            let decryptedBytes = try coreCrypto.perform { try $0.proteusDecrypt(
                sessionId: id,
                ciphertext: data.bytes
            ) }
            return decryptedBytes.data
        } catch {
            logger.error("failed to decrypt data: \(String(describing: error))")
            throw DecryptionError.failedToDecryptData
        }
    }

    // MARK: - proteusNewPrekey

    enum PrekeyError: Error {
        case failedToGeneratePrekey
        case prekeyCountTooLow
        case failedToGetLastPrekey
    }

    public func generatePrekey(id: UInt16) throws -> String {
        logger.info("generating prekey")

        do {
            return try coreCrypto.perform { try $0.proteusNewPrekey(prekeyId: id).base64EncodedString }
        } catch {
            logger.error("failed to generate prekey: \(String(describing: error))")
            throw PrekeyError.failedToGeneratePrekey
        }
    }

    public func lastPrekey() throws -> String {
        logger.info("getting last resort prekey")
        do {
            return try coreCrypto.perform { try $0.proteusLastResortPrekey().base64EncodedString }
        } catch {
            logger.error("failed to get last resort prekey: \(String(describing: error))")
            throw PrekeyError.failedToGetLastPrekey
        }
    }

    public var lastPrekeyID: UInt16 {
        let lastPrekeyID = try? coreCrypto.perform { try $0.proteusLastResortPrekeyId() }
        return lastPrekeyID ?? UInt16.max
    }

    public func generatePrekeys(start: UInt16 = 0, count: UInt16 = 0) throws -> [IdPrekeyTuple] {
        guard count > 0 else {
            throw PrekeyError.prekeyCountTooLow
        }

        let range = prekeysRange(count, start: start)
        let prekeys = try generatePrekeys(range)

        guard prekeys.count > 0 else {
            throw PrekeyError.failedToGeneratePrekey
        }

        return prekeys
    }

    private func generatePrekeys(_ range: CountableRange<UInt16>) throws -> [IdPrekeyTuple] {
        return try range.map {
            let prekey = try generatePrekey(id: $0)
            return (id: $0, prekey: prekey)
        }
    }

    private func prekeysRange(_ count: UInt16, start: UInt16) -> CountableRange<UInt16> {
        if start + count > lastPrekeyID {
            return 0 ..< count
        }
        return start ..< (start + count)
    }

    // MARK: - proteusFingerprint

    enum FingerprintError: Error {
        case failedToGetFingerprint
        case failedToGetLocalFingerprint
        case failedToGetRemoteFingerprint
        case failedToGetFingerprintFromPrekey
        case prekeyNotBase64Encoded
    }

    public func fingerprint() throws -> String {
        logger.info("fetching fingerprint")

        do {
            return try coreCrypto.perform { try $0.proteusFingerprint() }
        } catch {
            logger.error("failed to fetch fingerprint: \(String(describing: error))")
            throw FingerprintError.failedToGetFingerprint
        }
    }

    public func localFingerprint(forSession id: String) throws -> String {
        logger.info("fetching local fingerprint")

        do {
            return try coreCrypto.perform { try $0.proteusFingerprintLocal(sessionId: id) }
        } catch {
            logger.error("failed to fetch local fingerprint: \(String(describing: error))")
            throw FingerprintError.failedToGetLocalFingerprint
        }
    }

    public func remoteFingerprint(forSession id: String) throws -> String {
        logger.info("fetching remote fingerprint")

        do {
            return try coreCrypto.perform { try $0.proteusFingerprintRemote(sessionId: id) }
        } catch {
            logger.error("failed to fetch remote fingerprint: \(String(describing: error))")
            throw FingerprintError.failedToGetRemoteFingerprint
        }
    }

    public func fingerprint(fromPrekey prekey: String) throws -> String {
        logger.info("getting fingerprint from prekey")

        guard let prekeyBytes = prekey.base64EncodedBytes else {
            throw FingerprintError.prekeyNotBase64Encoded
        }

        do {
            return try coreCrypto.perform { try $0.proteusFingerprintPrekeybundle(prekey: prekeyBytes) }
        } catch {
            logger.error("failed to get fingerprint from prekey: \(String(describing: error))")
            throw FingerprintError.failedToGetFingerprintFromPrekey
        }
    }
}
