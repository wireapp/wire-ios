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
@testable import WireRequestStrategy
import WireTesting

class MessagingTestBase: ZMTBaseTest {

    var groupConversation: ZMConversation!
    fileprivate(set) var oneToOneConversation: ZMConversation!
    fileprivate(set) var oneToOneConnection: ZMConnection!
    fileprivate(set) var selfClient: UserClient!
    fileprivate(set) var otherUser: ZMUser!
    fileprivate(set) var thirdUser: ZMUser!
    fileprivate(set) var otherClient: UserClient!
    fileprivate(set) var otherEncryptionContext: EncryptionContext!
    fileprivate(set) var coreDataStack: CoreDataStack!
    fileprivate(set) var accountIdentifier: UUID!

    let owningDomain = "example.com"

    var useInMemoryStore: Bool {
        true
    }

    var syncMOC: NSManagedObjectContext! {
        return self.coreDataStack.syncContext
    }

    var uiMOC: NSManagedObjectContext! {
        return self.coreDataStack.viewContext
    }

    var eventMOC: NSManagedObjectContext! {
        return self.coreDataStack.eventContext
    }

    override class func setUp() {
        super.setUp()
        var flag = DeveloperFlag.proteusViaCoreCrypto
        flag.isOn = false
    }

    override func setUpWithError() throws {
        try super.setUpWithError()

        BackgroundActivityFactory.shared.activityManager = UIApplication.shared
        BackgroundActivityFactory.shared.resume()

        self.deleteAllOtherEncryptionContexts()
        self.deleteAllFilesInCache()
        self.accountIdentifier = UUID()
        self.coreDataStack = createCoreDataStack(userIdentifier: accountIdentifier,
                                                 inMemoryStore: useInMemoryStore)
        setupCaches(in: coreDataStack)
        setupTimers()

        self.syncMOC.performGroupedAndWait {
            self.syncMOC.zm_cryptKeyStore.deleteAndCreateNewBox()

            self.setupUsersAndClients()
            self.groupConversation = self.createGroupConversation(with: self.otherUser)
            self.oneToOneConversation = self.setupOneToOneConversation(with: self.otherUser)
            self.oneToOneConnection = self.otherUser.connection
            self.syncMOC.saveOrRollback()
        }
    }

    override func tearDown() {
        BackgroundActivityFactory.shared.activityManager = nil

        _ = self.waitForAllGroupsToBeEmpty(withTimeout: 10)

        self.syncMOC.performGroupedAndWait {
            self.otherUser = nil
            self.otherClient = nil
            self.selfClient = nil
            self.groupConversation = nil
        }
        self.stopEphemeralMessageTimers()

        _ = self.waitForAllGroupsToBeEmpty(withTimeout: 10)

        deleteAllFilesInCache()
        deleteAllOtherEncryptionContexts()

        accountIdentifier = nil
        coreDataStack = nil

        super.tearDown()
    }
}

// MARK: - Messages 
extension MessagingTestBase {

    /// Creates an update event with encrypted message from the other client, decrypts it and returns it
    func decryptedUpdateEventFromOtherClient(
        text: String,
        conversation: ZMConversation? = nil,
        source: ZMUpdateEventSource = .pushNotification,
        eventDecoder: EventDecoder
    ) async throws -> ZMUpdateEvent {
        return try await decryptedUpdateEventFromOtherClient(
            message: GenericMessage(content: Text(content: text)),
            conversation: conversation,
            source: source,
            eventDecoder: eventDecoder
        )
    }

    /// Creates an update event with encrypted message from the other client, decrypts it and returns it
    func decryptedUpdateEventFromOtherClient(
        message: GenericMessage,
        conversation: ZMConversation? = nil,
        source: ZMUpdateEventSource = .pushNotification,
        eventDecoder: EventDecoder
    ) async throws -> ZMUpdateEvent {

        let cyphertext = await syncMOC.perform { self.encryptedMessageToSelf(message: message, from: self.otherClient) }
        let innerPayload = await syncMOC.perform { [self] in
            ["recipient": selfClient.remoteIdentifier!,
             "sender": otherClient.remoteIdentifier!,
             "text": cyphertext.base64String()
            ]
        }

        return try await decryptedUpdateEventFromOtherClient(
            innerPayload: innerPayload,
            conversation: conversation,
            source: source,
            type: "conversation.otr-message-add",
            eventDecoder: eventDecoder
        )
    }

    /// Creates an update event with encrypted message from the other client, decrypts it and returns it
    func decryptedAssetUpdateEventFromOtherClient(
        message: GenericMessage,
        conversation: ZMConversation? = nil,
        source: ZMUpdateEventSource = .pushNotification,
        eventDecoder: EventDecoder
    ) async throws -> ZMUpdateEvent {

        let cyphertext = await syncMOC.perform { self.encryptedMessageToSelf(message: message, from: self.otherClient) }
        // Note: [F] added info to make it ZMSLog SafeTypes happy - this event conversation.otr-asset-add is deprecated
        let innerPayload = await syncMOC.perform { [self] in
            [
                "recipient": selfClient.remoteIdentifier!,
                "sender": otherClient.remoteIdentifier!,
                "id": UUID.create().transportString(),
                "key": cyphertext.base64String(),
                "info": cyphertext.base64String()
            ]
        }
        return try await decryptedUpdateEventFromOtherClient(
            innerPayload: innerPayload,
            conversation: conversation,
            source: source,
            type: "conversation.otr-asset-add",
            eventDecoder: eventDecoder
        )
    }

    func encryptedUpdateEventToSelfFromOtherClient(
        message: GenericMessage,
        conversation: ZMConversation? = nil,
        source: ZMUpdateEventSource = .pushNotification
    ) -> ZMUpdateEvent {
        let cyphertext = encryptedMessageToSelf(
            message: message,
            from: otherClient
        )

        let innerPayload = [
            "recipient": selfClient.remoteIdentifier!,
            "sender": otherClient.remoteIdentifier!,
            "text": cyphertext.base64String()
        ]

        return encryptedUpdateEventFromOtherClient(
            innerPayload: innerPayload,
            conversation: conversation,
            source: source,
            type: "conversation.otr-message-add"
        )
    }

    /// Creates an update event with encrypted message from the other client, decrypts it and returns it
    private func decryptedUpdateEventFromOtherClient(
        innerPayload: [String: Any],
        conversation: ZMConversation?,
        source: ZMUpdateEventSource,
        type: String,
        eventDecoder: EventDecoder
    ) async throws -> ZMUpdateEvent {
        let event = await syncMOC.perform {
            self.encryptedUpdateEventFromOtherClient(
                innerPayload: innerPayload,
                conversation: conversation,
                source: source,
                type: type
            )
        }

        var decryptedEvent: ZMUpdateEvent?
        let proteusProvider = await syncMOC.perform { self.syncMOC.proteusProvider }
        await proteusProvider.performAsync(withProteusService: { proteusService in

            decryptedEvent = await eventDecoder.decryptProteusEventAndAddClient(
                event,
                in: self.syncMOC
            ) { sessionID, encryptedData in
                let result = try await proteusService.decrypt(data: encryptedData, forSession: sessionID)
                return (didCreateNewSession: result.didCreateNewSession, decryptedData: result.decryptedData)
            }
        }, withKeyStore: { keyStore in
            await keyStore.encryptionContext.performAsync { session in
                decryptedEvent = await eventDecoder.decryptProteusEventAndAddClient(
                    event,
                    in: self.syncMOC
                ) { sessionID, encryptedData in
                    try session.decryptData(encryptedData, for: sessionID.mapToEncryptionSessionID())
                }
            }
        })
        return try XCTUnwrap(decryptedEvent)
    }

    private func encryptedUpdateEventFromOtherClient(
        innerPayload: [String: Any],
        conversation: ZMConversation?,
        source: ZMUpdateEventSource,
        type: String
    ) -> ZMUpdateEvent {

        let payload = [
            "type": type,
            "from": otherUser.remoteIdentifier!.transportString(),
            "data": innerPayload,
            "conversation": (conversation ?? groupConversation).remoteIdentifier!.transportString(),
            "time": Date().transportString()
        ] as [String: Any]
        let wrapper = [
            "id": UUID.create().transportString(),
            "payload": [payload]
        ] as [String: Any]

        return ZMUpdateEvent.eventsArray(from: wrapper as NSDictionary, source: source)!.first!
    }

    /// Extract the outgoing message wrapper (non-encrypted) protobuf
    func outgoingMessageWrapper(from request: ZMTransportRequest,
                                file: StaticString = #file,
                                line: UInt = #line) -> Proteus_NewOtrMessage? {
        guard let data = request.binaryData else {
            XCTFail("No binary data", file: file, line: line)
            return nil
        }
        return try? Proteus_NewOtrMessage(serializedData: data)
    }

    /// Extract encrypted payload from a request
    func outgoingEncryptedMessage(from request: ZMTransportRequest,
                                  for client: UserClient,
                                  line: UInt = #line,
                                  file: StaticString = #file
        ) -> GenericMessage? {

        guard let data = request.binaryData, let protobuf = try? Proteus_NewOtrMessage(serializedData: data) else {
            XCTFail("No binary data", file: file, line: line)
            return nil
        }

        let userEntries = protobuf.recipients.compactMap { $0 }
        guard let userEntry = userEntries.first(where: { $0.user == client.user?.userId }) else {
            XCTFail("User not found", file: file, line: line)
            return nil
        }
        // find client
        guard let clientEntry = userEntry.clients.first(where: { $0.client == client.clientId }) else {
            XCTFail("Client not found", file: file, line: line)
            return nil
        }

        // text content
        guard let plaintext = self.decryptMessageFromSelf(cypherText: clientEntry.text, to: self.otherClient) else {
            XCTFail("failed to decrypt", file: file, line: line)
            return nil
        }

        let receivedMessage = try? GenericMessage.init(serializedData: plaintext)
        return receivedMessage
    }
}

// MARK: - Internal data provisioning
extension MessagingTestBase {

    func setupOneToOneConversation(with user: ZMUser) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
        conversation.domain = owningDomain
        conversation.conversationType = .oneOnOne
        conversation.remoteIdentifier = UUID.create()
        user.connection = ZMConnection.insertNewObject(in: self.syncMOC)
        user.connection?.status = .accepted
        user.oneOnOneConversation = conversation
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        self.syncMOC.saveOrRollback()
        return conversation
    }

    /// Creates a user and a client
    func createUser(alsoCreateClient: Bool = false) -> ZMUser {
        return createUser(
            alsoCreateClient: alsoCreateClient,
            in: syncMOC
        )
    }

    /// Creates a new client for a user
    func createUser(
        alsoCreateClient: Bool = false,
        in context: NSManagedObjectContext
    ) -> ZMUser {
        let user = ZMUser.insertNewObject(in: context)
        user.remoteIdentifier = UUID.create()
        user.domain = owningDomain

        if alsoCreateClient {
            _ = self.createClient(
                user: user,
                in: context
            )
        }

        return user
    }

    /// Creates a new client for a user
    func createClient(user: ZMUser) -> UserClient {
        return createClient(
            user: user,
            in: syncMOC
        )
    }

    /// Creates a group conversation with a user
    func createClient(
        user: ZMUser,
        in context: NSManagedObjectContext
    ) -> UserClient {
        let client = UserClient.insertNewObject(in: context)
        client.remoteIdentifier = UUID.create().transportString()
        client.user = user
        context.saveOrRollback()
        return client
    }

    /// Creates a group conversation with a user
    func createGroupConversation(with user: ZMUser) -> ZMConversation {
        return createGroupConversation(
            with: user,
            in: syncMOC
        )
    }

    /// Creates a group conversation with a user
    func createGroupConversation(
        with user: ZMUser,
        in context: NSManagedObjectContext
    ) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: context)
        conversation.conversationType = .group
        conversation.domain = owningDomain
        conversation.remoteIdentifier = UUID.create()
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        conversation.addParticipantAndUpdateConversationState(user: ZMUser.selfUser(in: context), role: nil)
        conversation.needsToBeUpdatedFromBackend = false
        return conversation
    }

    func createOneToOneConversation(
        with user: ZMUser,
        in context: NSManagedObjectContext
    ) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: context)
        conversation.conversationType = .oneOnOne
        conversation.domain = owningDomain
        conversation.remoteIdentifier = UUID.create()
        user.connection = ZMConnection.insertNewObject(in: context)
        user.connection?.status = .accepted
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        return conversation
    }

    @discardableResult
    func createTeam() -> Team {
        return createTeam(in: syncMOC)
    }

    @discardableResult
    func createTeam(in context: NSManagedObjectContext) -> Team {
        let selfUser = ZMUser.selfUser(in: context)
        let teamID = UUID.create()
        selfUser.teamIdentifier = teamID

        let team = Team.insertNewObject(in: context)
        team.remoteIdentifier = teamID

        let member = Member.insertNewObject(in: context)
        member.team = team
        member.user = selfUser
        member.remoteIdentifier = selfUser.remoteIdentifier
        member.needsToBeUpdatedFromBackend = true
        member.permissions.insert(.member)

        return team
    }

    /// Creates an encryption context in a temp folder and creates keys
    fileprivate func setupUsersAndClients() {

        self.otherUser = self.createUser(alsoCreateClient: true)
        self.otherClient = self.otherUser.clients.first!
        self.thirdUser = self.createUser(alsoCreateClient: true)
        self.selfClient = self.createSelfClient()

        self.syncMOC.saveOrRollback()

        self.establishSessionFromSelf(to: self.otherClient)
    }

    /// Creates self client and user
    fileprivate func createSelfClient() -> UserClient {
        let user = ZMUser.selfUser(in: self.syncMOC)
        user.remoteIdentifier = UUID.create()
        user.domain = owningDomain

        let selfClient = UserClient.insertNewObject(in: self.syncMOC)
        selfClient.remoteIdentifier = "baddeed"
        selfClient.user = user

        self.syncMOC.setPersistentStoreMetadata(selfClient.remoteIdentifier!, key: ZMPersistedClientIdKey)
        selfClient.type = .permanent
        self.syncMOC.saveOrRollback()
        return selfClient
    }
}

// MARK: - Internal helpers
extension MessagingTestBase {

    func setupTimers() {
        syncMOC.performGroupedAndWait {
            syncMOC.zm_createMessageObfuscationTimer()
        }
        uiMOC.zm_createMessageDeletionTimer()
    }

    func stopEphemeralMessageTimers() {
        self.syncMOC.performGroupedAndWait {
            self.syncMOC.zm_teardownMessageObfuscationTimer()
        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        self.uiMOC.performGroupedAndWait {
            self.uiMOC.zm_teardownMessageDeletionTimer()
        }
        XCTAssert(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
}

// MARK: - Contexts
extension MessagingTestBase {

    override var allDispatchGroups: [ZMSDispatchGroup] {
        return super.allDispatchGroups + [self.syncMOC?.dispatchGroup, self.uiMOC?.dispatchGroup].compactMap { $0 }
    }

    func performPretendingUiMocIsSyncMoc(block: () -> Void) {
        uiMOC.resetContextType()
        uiMOC.markAsSyncContext()
        block()
        uiMOC.resetContextType()
        uiMOC.markAsUIContext()
    }
}

// MARK: - Cache cleaning
extension MessagingTestBase {

    private var cacheFolder: URL {
        return FileManager.default.randomCacheURL
    }

    fileprivate func deleteAllFilesInCache() {
        let files = try? FileManager.default.contentsOfDirectory(at: self.cacheFolder, includingPropertiesForKeys: [URLResourceKey.nameKey])
        files?.forEach {
            do {
                try FileManager.default.removeItem(at: $0)
            } catch {
                WireLogger.system.error("error deleting file  \($0.absoluteString) in cache: \(error)")
            }
        }
    }
}

// MARK: - Payload for message
extension MessagingTestBase {
    public func payloadForMessage(in conversation: ZMConversation?,
                                  type: String,
                                  data: Any) -> NSMutableDictionary? {
        return payloadForMessage(in: conversation!, type: type, data: data, time: nil)
    }

    public func payloadForMessage(in conversation: ZMConversation,
                                  type: String,
                                  data: Any,
                                  time: Date?) -> NSMutableDictionary? {
        //      {
        //         "conversation" : "8500be67-3d7c-4af0-82a6-ef2afe266b18",
        //         "data" : {
        //            "content" : "test test",
        //            "nonce" : "c61a75f3-285b-2495-d0f6-6f0e17f0c73a"
        //         },
        //         "from" : "39562cc3-717d-4395-979c-5387ae17f5c3",
        //         "id" : "11.800122000a4ab4f0",
        //         "time" : "2014-06-22T19:57:50.948Z",
        //         "type" : "conversation.message-add"
        //      }
        let user = ZMUser.insertNewObject(in: conversation.managedObjectContext!)
        user.remoteIdentifier = UUID.create()

        return payloadForMessage(in: conversation, type: type, data: data, time: time, from: user)
    }

    public func payloadForMessage(in conversation: ZMConversation,
                                  type: String,
                                  data: Any,
                                  time: Date?,
                                  from: ZMUser) -> NSMutableDictionary? {

        return ["conversation": conversation.remoteIdentifier?.transportString() ?? "",
                "data": data,
                "from": from.remoteIdentifier.transportString(),
                "time": time?.transportString() ?? "",
                "type": type
        ]
    }

    public func payloadForMessage(conversationID: UUID,
                                  domain: String?,
                                  type: String,
                                  data: Any,
                                  time: Date?,
                                  fromID: UUID) -> NSMutableDictionary? {

        return ["conversation": conversationID.transportString(),
                "qualified_conversation": [
                    "id": conversationID.transportString(),
                    "domain": domain
                ],
                "data": data,
                "from": fromID.transportString(),
                "time": time?.transportString() ?? "",
                "type": type
        ]
    }

}
