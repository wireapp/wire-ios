//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import XCTest

final class CoreCryptoCrossConnectionTests: XCTestCase {

    @MainActor
    func test_StaleWritePreservesSessionForFreshAndStaleReaders() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("CoreCryptoCrossConnectionTests-\(UUID().uuidString)", isDirectory: true)
        addTeardownBlock {
            try FileManager.default.removeItem(at: directory)
        }

        let failedReaders = try await Self.readersFailingAfterStaleWrite(in: directory)

        XCTAssertTrue(
            failedReaders.isEmpty,
            "Proteus 406 after a stale write for readers: \(failedReaders.joined(separator: ", "))"
        )
    }

    private static func readersFailingAfterStaleWrite(in directory: URL) async throws -> [String] {
        let key = try DatabaseKey(bytes: Data(repeating: 0x42, count: 32))
        let localURL = directory.appendingPathComponent("local/corecrypto")
        let peerURL = directory.appendingPathComponent("peer/corecrypto")
        let stale = try await makeCoreCrypto(at: localURL, key: key)
        let peer = try await makeCoreCrypto(at: peerURL, key: key)
        let prekey = try await peer.transaction { try await $0.proteusNewPrekeyAuto() }
        let initialMessage = Data("initial message".utf8)
        let initialCiphertext = try await stale.transaction { context in
            try await context.proteusSessionFromPrekey(sessionId: "peer", prekey: prekey.pkb)
            return try await context.proteusEncrypt(sessionId: "peer", plaintext: initialMessage)
        }
        let initialPlaintext = try await peer.transaction {
            try await $0.proteusDecryptSafe(sessionId: "local", ciphertext: initialCiphertext)
        }
        XCTAssertEqual(initialPlaintext, initialMessage)
        try await exchange("initial reply", from: peer, sessionID: "local", to: stale, receiverSessionID: "peer")

        // Each instance has its own connection. The stale instance now has the session cached.
        let other = try await makeCoreCrypto(at: localURL, key: key)
        try await exchange("other warmup", from: other, sessionID: "peer", to: peer, receiverSessionID: "local")
        try await exchange(
            "peer advances ratchet",
            from: peer,
            sessionID: "local",
            to: other,
            receiverSessionID: "peer"
        )
        try await exchange("other reply", from: other, sessionID: "peer", to: peer, receiverSessionID: "local")

        // Persist an outgoing message from the stale instance's cached state.
        _ = try await stale.transaction {
            try await $0.proteusEncrypt(sessionId: "peer", plaintext: Data("stale write".utf8))
        }
        let expectedPlaintext = Data("next peer message".utf8)
        let ciphertext = try await peer.transaction {
            try await $0.proteusEncrypt(sessionId: "local", plaintext: expectedPlaintext)
        }
        let fresh = try await makeCoreCrypto(at: localURL, key: key)

        var failedReaders: [String] = []
        for (name, reader) in [("fresh", fresh), ("stale", stale)] {
            do {
                let plaintext = try await decryptWithoutSaving(ciphertext, using: reader)
                XCTAssertEqual(plaintext, expectedPlaintext, "Unexpected plaintext for \(name) reader")
            } catch CoreCryptoError.Proteus(exception: .Other(errorCode: 406)) {
                failedReaders.append(name)
            } catch {
                XCTFail("Unexpected decryption error for \(name) reader: \(error)")
            }
        }
        return failedReaders
    }

    private static func makeCoreCrypto(at url: URL, key: DatabaseKey) async throws -> CoreCrypto {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let database = try await WireCoreCrypto.Database.open(location: url.path, key: key)
        let coreCrypto = try CoreCrypto(database: database)
        try await coreCrypto.transaction { try await $0.proteusInit() }
        return coreCrypto
    }

    private static func exchange(
        _ message: String,
        from sender: CoreCrypto,
        sessionID: String,
        to receiver: CoreCrypto,
        receiverSessionID: String
    ) async throws {
        let expected = Data(message.utf8)
        let ciphertext = try await sender.transaction {
            try await $0.proteusEncrypt(sessionId: sessionID, plaintext: expected)
        }
        let plaintext = try await receiver.transaction {
            try await $0.proteusDecrypt(sessionId: receiverSessionID, ciphertext: ciphertext)
        }
        XCTAssertEqual(plaintext, expected)
    }

    private struct DecryptionRollback: Error {
        let plaintext: Data
    }

    private static func decryptWithoutSaving(_ ciphertext: Data, using reader: CoreCrypto) async throws -> Data {
        do {
            return try await reader.transaction { context -> Data in
                let plaintext = try await context.proteusDecrypt(sessionId: "peer", ciphertext: ciphertext)
                // Roll back so the second reader can decrypt the same message from the same persisted state.
                throw DecryptionRollback(plaintext: plaintext)
            }
        } catch let result as DecryptionRollback {
            return result.plaintext
        }
    }
}
