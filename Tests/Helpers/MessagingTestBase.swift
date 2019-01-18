//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

import WireDataModel
import WireTesting
import WireCryptobox

class MessagingTestBase: ZMTBaseTest {
    
    fileprivate(set) var groupConversation: ZMConversation!
    fileprivate(set) var oneToOneConversation: ZMConversation!
    fileprivate(set) var selfClient: UserClient!
    fileprivate(set) var otherUser: ZMUser!
    fileprivate(set) var otherClient: UserClient!
    fileprivate(set) var otherEncryptionContext: EncryptionContext!
    fileprivate(set) var contextDirectory: ManagedObjectContextDirectory!
    fileprivate(set) var accountIdentifier: UUID!
    fileprivate(set) var sharedContainerURL: URL!
    
    var syncMOC: NSManagedObjectContext! {
        return self.contextDirectory.syncContext
    }
    
    var uiMOC: NSManagedObjectContext! {
        return self.contextDirectory.uiContext
    }

    override func setUp() {
        super.setUp()
        BackgroundActivityFactory.shared.activityManager = UIApplication.shared
        BackgroundActivityFactory.shared.resume()
        
        self.deleteAllOtherEncryptionContexts()
        self.deleteAllFilesInCache()
        
        self.sharedContainerURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.accountIdentifier = UUID()
        self.setupManagedObjectContexes()
        
        self.syncMOC.performGroupedBlockAndWait {
            self.syncMOC.zm_cryptKeyStore.deleteAndCreateNewBox()
            
            self.setupUsersAndClients()
            self.groupConversation = self.createGroupConversation(with: self.otherUser)
            self.oneToOneConversation = self.setupOneToOneConversation(with: self.otherUser)
            self.syncMOC.saveOrRollback()
        }
    }
    
    override func tearDown() {
        BackgroundActivityFactory.shared.activityManager = nil

        _ = self.waitForAllGroupsToBeEmpty(withTimeout: 10)
        self.syncMOC.performGroupedBlockAndWait {
            self.otherUser = nil
            self.otherClient = nil
            self.selfClient = nil
            self.groupConversation = nil
        }
        self.stopEphemeralMessageTimers()
        self.deleteAllFilesInCache()
        self.deleteAllOtherEncryptionContexts()
        
        _ = self.waitForAllGroupsToBeEmpty(withTimeout: 10)

        StorageStack.reset()
        _ = self.waitForAllGroupsToBeEmpty(withTimeout: 10)

        try? FileManager.default.contentsOfDirectory(at: sharedContainerURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles).forEach {
            try? FileManager.default.removeItem(at: $0)
        }

        accountIdentifier = nil
        sharedContainerURL = nil
        contextDirectory = nil

        super.tearDown()
    }
}

// MARK: - Messages 
extension MessagingTestBase {
    
    /// Creates an update event with encrypted message from the other client, decrypts it and returns it
    func decryptedUpdateEventFromOtherClient(text: String,
                                             conversation: ZMConversation? = nil,
                                             source: ZMUpdateEventSource = .pushNotification
        ) -> ZMUpdateEvent {
        
        let message = ZMGenericMessage.message(content: ZMText.text(with: text))
        return self.decryptedUpdateEventFromOtherClient(message: message, conversation: conversation, source: source)
    }
    
    /// Creates an update event with encrypted message from the other client, decrypts it and returns it
    func decryptedUpdateEventFromOtherClient(message: ZMGenericMessage,
                                             conversation: ZMConversation? = nil,
                                             source: ZMUpdateEventSource = .pushNotification
        ) -> ZMUpdateEvent {
        let cyphertext = self.encryptedMessageToSelf(message: message, from: self.otherClient)
        let innerPayload = ["recipient": self.selfClient.remoteIdentifier!,
                            "sender": self.otherClient.remoteIdentifier!,
                            "text": cyphertext.base64String()
        ]
        return self.decryptedUpdateEventFromOtherClient(innerPayload: innerPayload,
                                                        conversation: conversation,
                                                        source: source,
                                                        type: "conversation.otr-message-add"
        )
    }
    
    /// Creates an update event with encrypted message from the other client, decrypts it and returns it
    func decryptedAssetUpdateEventFromOtherClient(message: ZMGenericMessage,
                                             conversation: ZMConversation? = nil,
                                             source: ZMUpdateEventSource = .pushNotification
        ) -> ZMUpdateEvent {
        let cyphertext = self.encryptedMessageToSelf(message: message, from: self.otherClient)
        let innerPayload = ["recipient": self.selfClient.remoteIdentifier!,
                            "sender": self.otherClient.remoteIdentifier!,
                            "id": UUID.create().transportString(),
                            "key": cyphertext.base64String()
        ]
        return self.decryptedUpdateEventFromOtherClient(innerPayload: innerPayload,
                                                        conversation: conversation,
                                                        source: source,
                                                        type: "conversation.otr-asset-add"
                            )
    }
    
    /// Creates an update event with encrypted message from the other client, decrypts it and returns it
    private func decryptedUpdateEventFromOtherClient(innerPayload: [String: Any],
                                                  conversation: ZMConversation?,
                                                  source: ZMUpdateEventSource,
                                                  type: String
        ) -> ZMUpdateEvent {
        let payload = [
            "type": type,
            "from": self.otherUser.remoteIdentifier!.transportString(),
            "data": innerPayload,
            "conversation": (conversation ?? self.groupConversation).remoteIdentifier!.transportString(),
            "time": Date().transportString()
            ] as [String: Any]
        let wrapper = [
            "id": UUID.create().transportString(),
            "payload": [payload]
            ] as [String: Any]
        
        let event = ZMUpdateEvent.eventsArray(from: wrapper as NSDictionary, source: source)!.first!
        
        var decryptedEvent: ZMUpdateEvent?
        self.selfClient.keysStore.encryptionContext.perform { session in
            decryptedEvent = session.decryptAndAddClient(event, in: self.syncMOC)
        }
        return decryptedEvent!
    }
    
    /// Extract the outgoing message wrapper (non-encrypted) protobuf
    func outgoingMessageWrapper(from request: ZMTransportRequest,
                                file: StaticString = #file,
                                line: UInt = #line) -> ZMNewOtrMessage? {
        guard let protobuf = ZMNewOtrMessage.parse(from: request.binaryData) else {
            XCTFail("No binary data", file: file, line: line)
            return nil
        }
        return protobuf
    }
    
    /// Extract encrypted payload from a request
    func outgoingEncryptedMessage(from request: ZMTransportRequest,
                                  for client: UserClient,
                                  line: UInt = #line,
                                  file: StaticString = #file
        ) -> ZMGenericMessage? {
        
        guard let protobuf = ZMNewOtrMessage.parse(from: request.binaryData) else {
            XCTFail("No binary data", file: file, line: line)
            return nil
        }
        // find user
        guard let recipients = protobuf.recipients else {
            XCTFail("Recipients not found")
            return nil
        }
        let userEntries = recipients.compactMap { $0 }
        guard let userEntry = userEntries.first(where: { $0.user == client.user!.userId() }) else {
            XCTFail("User not found", file: file, line: line)
            return nil
        }
        // find client
        guard let clientEntry = userEntry.clients.first(where: { $0.client == client.clientId }) else {
            XCTFail("Client not found", file: file, line: line)
            return nil
        }
        
        // text content
        guard let cyphertext = clientEntry.text else {
            XCTFail("No text", file: file, line: line)
            return nil
        }
        guard let plaintext = self.decryptMessageFromSelf(cypherText: cyphertext, to: self.otherClient) else {
            XCTFail("failed to decrypt", file: file, line: line)
            return nil
        }
        guard let receivedMessage = ZMGenericMessage.parse(from: plaintext) else {
            XCTFail("Invalid message")
            return nil
        }
        return receivedMessage
    }
}

// MARK: - Internal data provisioning
extension MessagingTestBase {
    
    fileprivate func setupOneToOneConversation(with user: ZMUser) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
        conversation.conversationType = .oneOnOne
        conversation.remoteIdentifier = UUID.create()
        conversation.connection = ZMConnection.insertNewObject(in: self.syncMOC)
        conversation.connection?.to = user
        conversation.connection?.status = .accepted
        conversation.mutableLastServerSyncedActiveParticipants.add(user)
        self.syncMOC.saveOrRollback()
        return conversation
    }
    
    /// Creates a user and a client
    func createUser(alsoCreateClient: Bool = false) -> ZMUser {
        let user = ZMUser.insertNewObject(in: self.syncMOC)
        user.remoteIdentifier = UUID.create()
        if alsoCreateClient {
            _ = self.createClient(user: user)
        }
        return user
    }
    
    /// Creates a new client for a user
    func createClient(user: ZMUser) -> UserClient {
        let client = UserClient.insertNewObject(in: self.syncMOC)
        client.remoteIdentifier = UUID.create().transportString()
        client.user = user
        self.syncMOC.saveOrRollback()
        return client
    }
    
    /// Creates a group conversation with a user
    func createGroupConversation(with user: ZMUser) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
        conversation.conversationType = .group
        conversation.remoteIdentifier = UUID.create()
        conversation.mutableLastServerSyncedActiveParticipants.add(user)
        return conversation
    }
    
    /// Creates an encryption context in a temp folder and creates keys
    fileprivate func setupUsersAndClients() {
        
        self.otherUser = self.createUser(alsoCreateClient: true)
        self.otherClient = self.otherUser.clients.first!
        self.selfClient = self.createSelfClient()
        
        self.syncMOC.saveOrRollback()
        
        self.establishSessionFromSelf(to: self.otherClient)
    }
    
    /// Creates self client and user
    fileprivate func createSelfClient() -> UserClient {
        let user = ZMUser.selfUser(in: self.syncMOC)
        user.remoteIdentifier = UUID.create()
        
        let selfClient = UserClient.insertNewObject(in: self.syncMOC)
        selfClient.remoteIdentifier = "baddeed"
        selfClient.user = user
        
        self.syncMOC.setPersistentStoreMetadata(selfClient.remoteIdentifier!, key: "PersistedClientId")
        selfClient.type = "permanent"
        self.syncMOC.saveOrRollback()
        return selfClient
    }
}

// MARK: - Internal helpers
extension MessagingTestBase {
    
    func setupTimers() {
        syncMOC.performGroupedAndWait() {
            $0.zm_createMessageObfuscationTimer()
        }
        uiMOC.zm_createMessageDeletionTimer()
    }
    
    func stopEphemeralMessageTimers() {
        self.syncMOC.performGroupedBlockAndWait {
            self.syncMOC.zm_teardownMessageObfuscationTimer()
        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        self.uiMOC.performGroupedBlockAndWait {
            self.uiMOC.zm_teardownMessageDeletionTimer()
        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
}

// MARK: - Contexts
extension MessagingTestBase {

    fileprivate func setupManagedObjectContexes() {
        StorageStack.reset()
        StorageStack.shared.createStorageAsInMemory = true

        StorageStack.shared.createManagedObjectContextDirectory(
            accountIdentifier: accountIdentifier,
            applicationContainer: sharedContainerURL,
            dispatchGroup: dispatchGroup,
            completionHandler: { self.contextDirectory = $0 }
        )

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.1))

        let fileAssetCache = FileAssetCache(location: nil)
        self.uiMOC.userInfo["TestName"] = self.name
        
        self.syncMOC.performGroupedBlockAndWait {
            self.syncMOC.userInfo["TestName"] = self.name
            self.syncMOC.saveOrRollback()
            
            self.syncMOC.zm_userInterface = self.uiMOC
            self.syncMOC.zm_fileAssetCache = fileAssetCache
        }
        
        self.uiMOC.zm_sync = self.syncMOC
        self.uiMOC.zm_fileAssetCache = fileAssetCache
        
        setupTimers()
    }

    override var allDispatchGroups: [ZMSDispatchGroup] {
        return super.allDispatchGroups + [self.syncMOC?.dispatchGroup, self.uiMOC?.dispatchGroup].compactMap { $0 }
    }
}


// MARK: - Cache cleaning
extension MessagingTestBase {
    
    private var cacheFolder: URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }

    fileprivate func deleteAllFilesInCache() {
        let files = try? FileManager.default.contentsOfDirectory(at: self.cacheFolder, includingPropertiesForKeys: [URLResourceKey.nameKey])
        files?.forEach {
            try! FileManager.default.removeItem(at: $0)
        }
    }
}
