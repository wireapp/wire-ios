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

import GenericMessageProtocol
import WireCoreCrypto
@preconcurrency import WireDataModel
import WireDataModelSupport
import WireTesting
import XCTest

/// Simulates remote Proteus clients for testing encryption/decryption scenarios.
/// Each simulated client has its own ProteusService and CoreCrypto instance.
final class ProteusClientSimulator {

    private let syncMOC: NSManagedObjectContext
    private let owningDomain: String
    private let storageURL: URL

    /// Dictionary to store ProteusService instances for simulated remote clients
    private var clientServices: [String: (service: ProteusServiceInterface, coreCrypto: SafeCoreCryptoProtocol)] = [:]

    init(syncMOC: NSManagedObjectContext, owningDomain: String, storageURL: URL) {
        self.syncMOC = syncMOC
        self.owningDomain = owningDomain
        self.storageURL = storageURL
    }

    /// Gets or creates a ProteusService for a test client (simulating a remote client)
    func proteusService(for client: UserClient) async throws -> ProteusServiceInterface {

        // Ensure client has remote identifier and return it
        let clientKey = try await syncMOC.perform { [syncMOC, objectID = client.objectID] in
            let client = try syncMOC.existingObject(with: objectID) as! UserClient

            guard let remoteIdentifier = client.remoteIdentifier else {
                let id = UUID.create().transportString()
                client.remoteIdentifier = id
                return id
            }

            return remoteIdentifier
        }

        if let existing = clientServices[clientKey] {
            return existing.service
        }

        // Create CoreCrypto instance for this client via CoreCryptoProvider
        let clientDirectory = storageURL
            .appendingPathComponent("client-\(clientKey)")
        try FileManager.default.createDirectory(
            at: clientDirectory,
            withIntermediateDirectories: true,
            attributes: [:]
        )

        let mockKeyMigrationManager = MockCoreCryptoKeyMigrationManagerProtocol()
        mockKeyMigrationManager.isKeyRotationNeeded = false
        mockKeyMigrationManager.isMigrationToBytesNeeded = false
        mockKeyMigrationManager.isMigrationToScopedKeyNeeded = false

        let clientUserID = UUID.create()
        let coreCryptoProvider = CoreCryptoProvider(
            selfUserID: clientUserID,
            sharedContainerURL: storageURL,
            accountDirectory: clientDirectory,
            sharedUserDefaults: UserDefaults.standard,
            syncContext: syncMOC,
            cryptoboxMigrationManager: CryptoboxMigrationManager(),
            coreCryptoKeyMigrationManager: mockKeyMigrationManager,
            allowCreation: true,
            localDomain: owningDomain
        )

        // Initialize CoreCrypto
        let coreCrypto = try await coreCryptoProvider.coreCrypto()

        let proteusService = ProteusService(coreCryptoProvider: coreCryptoProvider)
        clientServices[clientKey] = (service: proteusService, coreCrypto: coreCrypto)

        return proteusService
    }

    /// Encrypts a message from the given client to the self user using ProteusService
    /// It will create a session between the two if needed
    func encryptedMessageToSelf(message: GenericMessage, from sender: UserClient) async throws -> Data {
        // Ensure sender has remote identifier and get selfSessionID
        let selfSessionID = try await syncMOC.perform { [syncMOC] in
            let selfClient = try XCTUnwrap(ZMUser.selfUser(in: syncMOC).selfClient())
            let selfUser = try XCTUnwrap(selfClient.user)

            // Ensure self user and client have identifiers
            if selfUser.remoteIdentifier == nil {
                selfUser.remoteIdentifier = UUID()
            }
            if selfClient.remoteIdentifier == nil {
                selfClient.remoteIdentifier = UUID.create().transportString()
            }

            // Ensure sender has remote identifier
            if sender.remoteIdentifier == nil {
                sender.remoteIdentifier = UUID.create().transportString()
            }

            return try XCTUnwrap(selfClient.proteusSessionID)
        }

        let senderProteusService = try await proteusService(for: sender)

        // Check if session exists, if not: establish it
        if !(await senderProteusService.sessionExists(id: selfSessionID)) {
            // Get self's last prekey
            let selfProteusService = try await getSelfProteusService()
            let lastPrekey = try await selfProteusService.lastPrekey()

            // Establish session from sender to self
            try await senderProteusService.establishSession(id: selfSessionID, fromPrekey: lastPrekey)
        }

        // Encrypt the message
        return try await senderProteusService.encrypt(
            data: message.serializedData(),
            forSession: selfSessionID
        )
    }

    /// Creates a session between the self client to the given user, if it does not
    /// exists already
    func establishSessionFromSelf(to client: UserClient) async throws {
        let selfProteusService = try await getSelfProteusService()

        guard let clientSessionID = await syncMOC.perform({ client.proteusSessionID }) else {
            return XCTFail("Client session ID not available")
        }

        // Check if session already exists
        if await selfProteusService.sessionExists(id: clientSessionID) {
            return
        }

        // Get prekey from the other client
        let clientProteusService = try await proteusService(for: client)
        let prekey = try await clientProteusService.lastPrekey()

        // Establish session from self to client
        try await selfProteusService.establishSession(id: clientSessionID, fromPrekey: prekey)
    }

    /// Decrypts a message from self to a given client using ProteusService
    func decryptMessageFromSelf(cypherText: Data, to client: UserClient) async throws -> Data? {
        // Get self session ID in context
        guard let selfSessionID = await syncMOC.perform({ [syncMOC] in
            ZMUser.selfUser(in: syncMOC).selfClient()?.proteusSessionID
        }) else {
            XCTFail("Self session ID not available")
            return nil
        }

        let clientProteusService = try await proteusService(for: client)

        do {
            let result = try await clientProteusService.decrypt(
                data: cypherText,
                forSession: selfSessionID,
                context: nil
            )
            return result.decryptedData
        } catch {
            XCTFail("Decryption error: \(error)")
            return nil
        }
    }

    /// Delete all simulated client ProteusService instances and their storage
    func cleanup() {
        // Tear down all CoreCrypto instances
        for (_, entry) in clientServices {
            try? entry.coreCrypto.tearDown()
        }

        clientServices.removeAll()

        // Delete storage
        try? FileManager.default.removeItem(at: storageURL)
    }

    private func getSelfProteusService() async throws -> ProteusServiceInterface {
        let proteusService = await syncMOC.perform { [syncMOC] in
            syncMOC.proteusService
        }
        return try XCTUnwrap(proteusService)
    }
}
