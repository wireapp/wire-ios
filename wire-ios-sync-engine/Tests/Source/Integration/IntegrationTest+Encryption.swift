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
import WireCryptobox
import WireDataModel
import WireMockTransport
import WireTesting
import XCTest

extension IntegrationTest {
    /// Encrypts a message from the given client to the self user.
    /// It will create a session between the two if needed
    public func encryptedMessageToSelf(message: GenericMessage, from sender: UserClient) -> Data {
        let selfClient = ZMUser.selfUser(in: userSession!.syncManagedObjectContext).selfClient()!
        if selfClient.user!.remoteIdentifier == nil {
            selfClient.user!.remoteIdentifier = UUID()
        }
        if selfClient.remoteIdentifier == nil {
            selfClient.remoteIdentifier = .randomRemoteIdentifier()
        }

        var cypherText: Data?
        encryptionContext(for: sender).perform { session in
            if !session.hasSession(for: selfClient.sessionIdentifier!) {
                // swiftlint:disable:next todo_requires_jira_link
                // TODO: [John] use flag here
                guard let lastPrekey = try? userSession!.syncContext.zm_cryptKeyStore.lastPreKey() else {
                    fatalError("Can't get prekey for self user")
                }
                try! session.createClientSession(selfClient.sessionIdentifier!, base64PreKeyString: lastPrekey)
            }

            do {
                cypherText = try session.encrypt(message.serializedData(), for: selfClient.sessionIdentifier!)
            } catch {
                fatalError("Error in encrypting: \(error)")
            }
        }
        return cypherText!
    }

    /// Creates a session between the self client to the given user, if it does not
    /// exists already
    public func establishSessionFromSelf(to client: UserClient) async {
        let context = userSession!.syncManagedObjectContext

        // this makes sure the client has remote identifier
        await context.perform { _ = self.encryptionContext(for: client) }

        var hasSessionWithSelfClient = false
        userSession!.syncContext.zm_cryptKeyStore.encryptionContext.perform { sessionsDirectory in
            hasSessionWithSelfClient = sessionsDirectory.hasSession(for: client.sessionIdentifier!)
        }

        if hasSessionWithSelfClient {
            // done!
            return
        }

        await context.perform {
            _ = ZMUser.selfUser(in: context).selfClient()!
            var prekey: String?
            self.encryptionContext(for: client).perform { session in
                do {
                    prekey = try session.generateLastPrekey()
                } catch {
                    XCTFail("unexpected error: \(String(reflecting: error))")
                }
            }

            // swiftlint:disable:next todo_requires_jira_link
            // TODO: [John] use flag here
            context.zm_cryptKeyStore.encryptionContext.perform { session in
                do {
                    try session.createClientSession(client.sessionIdentifier!, base64PreKeyString: prekey!)
                } catch {
                    XCTFail("unexpected error: \(String(reflecting: error))")
                }
            }
        }
    }

    /// Creates a session between the self client, and a client matching a remote client.
    /// If no such client exists locally, it creates it (and the user associated with it).
    public func establishSessionFromSelf(toRemote remoteClient: MockUserClient) async {
        let mockContext = mockTransportSession.managedObjectContext
        // .syncManagedObjectContext
        guard let remoteUserIdentifierString = await mockContext.perform({ remoteClient.user?.identifier }),
              let remoteUserIdentifier = UUID(uuidString: remoteUserIdentifierString),
              let remoteClientIdentifier = await mockContext.perform({ remoteClient.identifier }) else {
            fatalError("You should set up remote client with user and identifier")
        }

        let context = userSession!.syncManagedObjectContext

        let (localClient, lastPrekey) = await context.perform {
            // create user
            let localUser = ZMUser.fetchOrCreate(with: remoteUserIdentifier, domain: nil, in: context)

            // create client
            let localClient = localUser.clients
                .first(where: { $0.remoteIdentifier == remoteClientIdentifier }) ?? { () -> UserClient in
                    let newClient = UserClient.insertNewObject(in: context)
                    newClient.user = localUser
                    newClient.remoteIdentifier = remoteClientIdentifier
                    return newClient
                }()
            context.saveOrRollback()

            var lastPrekey: String!
            self.mockTransportSession.performRemoteChanges { _ in
                lastPrekey = remoteClient.lastPrekey.value
            }
            return (localClient, lastPrekey)
        }

        var hasSessionWithLocalClient = false
        let syncContext = userSession!.syncContext

        await syncContext.perform {
            syncContext.zm_cryptKeyStore.encryptionContext.perform { sessionsDirectory in
                hasSessionWithLocalClient = sessionsDirectory.hasSession(for: localClient.sessionIdentifier!)
            }

            if !hasSessionWithLocalClient {
                // swiftlint:disable:next todo_requires_jira_link
                // TODO: [John] use flag here
                syncContext.zm_cryptKeyStore.encryptionContext.perform { session in
                    try! session.createClientSession(localClient.sessionIdentifier!, base64PreKeyString: lastPrekey!)
                }
            }
        }
    }

    /// Decrypts a message that was sent from self to a given user
    public func decryptMessageFromSelf(cypherText: Data, to client: UserClient) -> Data? {
        let selfClient = ZMUser.selfUser(in: userSession!.syncManagedObjectContext).selfClient()!
        var plainText: Data?
        encryptionContext(for: client).perform { session in
            if session.hasSession(for: selfClient.sessionIdentifier!) {
                do {
                    plainText = try session.decrypt(cypherText, from: selfClient.sessionIdentifier!)
                } catch {
                    XCTFail("Decryption error: \(error)")
                }
            } else {
                do {
                    plainText = try session.createClientSessionAndReturnPlaintext(
                        for: selfClient.sessionIdentifier!,
                        prekeyMessage: cypherText
                    )
                } catch {
                    XCTFail("Decryption error: \(error)")
                }
            }
        }
        return plainText
    }
}

extension IntegrationTest {
    /// Delete all other clients encryption contexts
    public func deleteAllOtherEncryptionContexts() {
        try?  FileManager.default.removeItem(at: otherClientsEncryptionContextsURL)
    }

    /// Returns the folder where the encryption contexts for other test clients are stored
    var otherClientsEncryptionContextsURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("OtherClients")
    }

    /// Returns the encryption context to use for a given client. There are extra cryptobox sessions
    /// that simulate a remote client able to decrypt/encrypt data with its own cryptobox instance.
    /// If the client has no remote identifier, it will create one
    private func encryptionContext(for client: UserClient) -> EncryptionContext {
        if client.remoteIdentifier == nil {
            client.remoteIdentifier = .randomRemoteIdentifier()
        }
        let url = otherClientsEncryptionContextsURL.appendingPathComponent("client-\(client.remoteIdentifier!)")
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: [:])
        let encryptionContext = EncryptionContext(path: url)
        return encryptionContext
    }
}
