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

import WireCoreCrypto
import XCTest
@testable import WireDataModel
@testable import WireDataModelSupport

final class SafeCoreCryptoTests: XCTestCase {

    func testRetainedWrapperDecryptsAfterAnotherInstanceUpdatesTheGroup() async throws {
        for commitCount in 1 ... 2 {
            let fixture = try await CryptoFixture(fileBacked: true)
            let sut = fixture.wrapper()
            for _ in 0 ..< commitCount {
                let commit = try await fixture.updateBob()
                let otherInstance = try await fixture.freshAlice(database: fixture.externalDatabase)
                _ = try await otherInstance.transaction {
                    try await $0.decryptMessage(conversationId: fixture.groupID, payload: commit)
                }
            }
            let message = try await fixture.encryptBob()

            // The cached instance still uses the old group state, even though the shared database has advanced.
            let cachedResult = try await fixture.alice.transaction { context -> Result<DecryptedMessage, Error> in
                do {
                    return try await .success(
                        context.decryptMessage(conversationId: fixture.groupID, payload: message)
                    )
                } catch {
                    return .failure(error)
                }
            }
            switch cachedResult {
            case .failure(CoreCryptoError.Mls(.BufferedFutureMessage)), .failure(CoreCryptoError.Mls(.WrongEpoch)):
                break
            default:
                XCTFail("Expected the cached instance to reject the future epoch")
            }

            let decrypted = try await sut.transaction { context in
                // Credential reads on the cached instance must also work inside the fresh transaction.
                _ = try await sut.coreCrypto.getCredentials()
                return try await context.decryptMessage(conversationId: fixture.groupID, payload: message)
            }
            guard case let .text(plaintext, _, _) = decrypted else {
                return XCTFail("Expected the same message to decrypt through the retained wrapper")
            }
            XCTAssertEqual(plaintext, fixture.plaintext)
        }
    }

    func testBufferedMessageSurvivesUntilTheCommitArrives() async throws {
        let fixture = try await CryptoFixture()
        let sut = fixture.wrapper()
        let commit = try await fixture.updateBob()
        let message = try await fixture.encryptBob()

        let result = try await sut.transaction { context -> Result<DecryptedMessage, Error> in
            do {
                return try await .success(context.decryptMessage(conversationId: fixture.groupID, payload: message))
            } catch {
                return .failure(error)
            }
        }
        guard case .failure(CoreCryptoError.Mls(.BufferedFutureMessage)) = result else {
            return XCTFail("Expected a buffered future message")
        }

        let decrypted = try await sut.transaction {
            try await $0.decryptMessage(conversationId: fixture.groupID, payload: commit)
        }
        guard case let .commit(_, messages?, _) = decrypted else {
            return XCTFail("Expected the buffered message when the commit arrives")
        }
        XCTAssertTrue(messages.contains {
            if case let .text(plaintext, _, _) = $0 { return plaintext == fixture.plaintext }
            return false
        })
    }

    func testEpochObserverReceivesUpdatesFromSuccessiveTransactions() async throws {
        let fixture = try await CryptoFixture()
        let updates = expectation(description: "epoch updates")
        updates.expectedFulfillmentCount = 2
        let registration = EpochObserverRegistration()
        registration.setObserver(CryptoEpochObserver(updates: updates))
        let sut = SafeCoreCrypto(
            backgroundTaskExecuter: PassthroughTaskExecuter(),
            coreCrypto: fixture.alice,
            transactionCoreCryptoFactory: {
                let fresh = try await fixture.freshAlice()
                try await registration.register(with: fresh)
                return fresh
            }
        )
        for _ in 0 ..< 2 {
            try await sut.transaction {
                try await $0.updateKeyingMaterial(conversationId: fixture.groupID)
            }
        }
        await fulfillment(of: [updates], timeout: 2)
    }

    func testProteusSessionSurvivesFreshTransactionInstances() async throws {
        let database = try await WireCoreCryptoUniffi.Database.open()
        let alice = try CoreCrypto(database: database)
        let bobDatabase = try await WireCoreCryptoUniffi.Database.open()
        let bob = try CoreCrypto(database: bobDatabase)
        let prekey = try await bob.transaction { context in
            try await context.proteusInit()
            return try await context.proteusNewPrekey(prekeyId: 1)
        }
        let sut = SafeCoreCrypto(
            backgroundTaskExecuter: PassthroughTaskExecuter(),
            coreCrypto: alice,
            transactionCoreCryptoFactory: {
                let fresh = try CoreCrypto(database: database)
                try await fresh.transaction { try await $0.proteusInit() }
                return fresh
            }
        )
        try await sut.transaction {
            try await $0.proteusSessionFromPrekey(sessionId: "bob", prekey: prekey)
        }
        let plaintext = Data("call signal".utf8)
        let encrypted = try await sut.transaction {
            try await $0.proteusEncrypt(sessionId: "bob", plaintext: plaintext)
        }
        let received = try await bob.transaction {
            try await $0.proteusDecryptSafe(sessionId: "alice", ciphertext: encrypted)
        }
        XCTAssertEqual(received, plaintext)
        let reply = try await bob.transaction {
            try await $0.proteusEncrypt(sessionId: "alice", plaintext: plaintext)
        }
        let decryptedReply = try await sut.transaction {
            try await $0.proteusDecryptSafe(sessionId: "bob", ciphertext: reply)
        }
        XCTAssertEqual(decryptedReply, plaintext)
    }

}

private final class CryptoEpochObserver: EpochObserver {

    let updates: XCTestExpectation

    init(updates: XCTestExpectation) {
        self.updates = updates
    }

    func epochChanged(conversationId: ConversationId, epoch: UInt64) async throws {
        updates.fulfill()
    }

}

private final class CryptoFixture {

    let database: WireCoreCryptoUniffi.Database
    let externalDatabase: WireCoreCryptoUniffi.Database
    let alice: CoreCrypto
    let bob: CoreCrypto
    let aliceID: ClientId
    let groupID = ConversationId(bytes: Data("call-answer-test".utf8))
    let plaintext = Data("answered on another client".utf8)
    private let aliceTransport = CryptoTransport()
    private let bobTransport = CryptoTransport()

    init(fileBacked: Bool = false) async throws {
        if fileBacked {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let location = directory.appendingPathComponent("crypto.db").path
            let key = try DatabaseKey(bytes: Data(repeating: 0xA5, count: 32))
            self.database = try await WireCoreCryptoUniffi.Database.open(location: location, key: key)
            self.externalDatabase = try await WireCoreCryptoUniffi.Database.open(location: location, key: key)
        } else {
            self.database = try await WireCoreCryptoUniffi.Database.open()
            self.externalDatabase = database
        }
        self.alice = try CoreCrypto(database: database)
        let bobDatabase = try await WireCoreCryptoUniffi.Database.open()
        self.bob = try CoreCrypto(database: bobDatabase)
        self.aliceID = ClientId(
            userId: try Uuid(uuid: UUID().uuidString),
            deviceId: DeviceId(id: 1),
            domain: "test.invalid"
        )
        let bobID = ClientId(
            userId: try Uuid(uuid: UUID().uuidString),
            deviceId: DeviceId(id: 2),
            domain: "test.invalid"
        )
        let suite = CipherSuite.mls128Dhkemx25519Aes128gcmSha256Ed25519
        try await alice.transaction { [self] context in
            try await context.mlsInit(clientId: aliceID, transport: aliceTransport)
            let credential = try Credential.basic(cipherSuite: suite, clientId: aliceID)
            let reference = try await context.addCredential(credential: credential)
            try await context.createConversation(conversationId: groupID, credentialRef: reference, externalSender: nil)
        }
        let package = try await bob.transaction { [self] context in
            try await context.mlsInit(clientId: bobID, transport: bobTransport)
            let credential = try Credential.basic(cipherSuite: suite, clientId: bobID)
            let reference = try await context.addCredential(credential: credential)
            return try await context.generateKeyPackage(credentialRef: reference, lifetime: nil)
        }
        try await alice.transaction { [self] in
            try await $0.addClientsToConversation(conversationId: groupID, keyPackages: [package])
        }
        let welcome = try XCTUnwrap(aliceTransport.bundle?.welcome)
        _ = try await bob.transaction {
            try await $0.processWelcomeMessage(welcomeMessage: welcome)
        }
    }

    func freshAlice(database: WireCoreCryptoUniffi.Database? = nil) async throws -> CoreCrypto {
        let fresh = try CoreCrypto(database: database ?? self.database)
        try await fresh.transaction { [self] in
            try await $0.mlsInit(clientId: aliceID, transport: aliceTransport)
        }
        return fresh
    }

    func wrapper() -> SafeCoreCrypto {
        SafeCoreCrypto(
            backgroundTaskExecuter: PassthroughTaskExecuter(),
            coreCrypto: alice,
            transactionCoreCryptoFactory: { try await self.freshAlice() }
        )
    }

    func updateBob() async throws -> Data {
        try await bob.transaction { [self] in
            try await $0.updateKeyingMaterial(conversationId: groupID)
        }
        return try XCTUnwrap(bobTransport.bundle).commit
    }

    func encryptBob() async throws -> Data {
        try await bob.transaction { [self] in
            try await $0.encryptMessage(conversationId: groupID, message: plaintext)
        }
    }

}

private final class CryptoTransport: MlsTransport, @unchecked Sendable {

    private let lock = NSLock()
    private var lastBundle: CommitBundle?

    var bundle: CommitBundle? {
        lock.lock()
        defer { lock.unlock() }
        return lastBundle
    }

    private func store(_ bundle: CommitBundle) {
        lock.lock()
        defer { lock.unlock() }
        lastBundle = bundle
    }

    func sendCommitBundle(commitBundle: CommitBundle) async throws {
        store(commitBundle)
    }

    func prepareForTransport(historySecret: HistorySecret) async -> Data {
        historySecret.data
    }

}
