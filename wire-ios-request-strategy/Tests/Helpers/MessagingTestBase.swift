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
import WireDataModel
import WireDataModelSupport
import WireLogging
import WireTesting

@testable import WireRequestStrategy

class MessagingTestBase: ZMTBaseTest {

    var groupConversation: ZMConversation!
    fileprivate(set) var oneToOneConversation: ZMConversation!
    fileprivate(set) var oneToOneConnection: ZMConnection!
    fileprivate(set) var selfClient: UserClient!
    fileprivate(set) var otherUser: ZMUser!
    fileprivate(set) var thirdUser: ZMUser!
    fileprivate(set) var otherClient: UserClient!
    fileprivate(set) var coreDataStack: CoreDataStack!
    fileprivate(set) var accountIdentifier: UUID!

    // Lazy Proteus/CoreCrypto properties - only initialized when accessed
    private var _coreCrypto: SafeCoreCrypto?
    private var _proteusService: ProteusServiceInterface?
    private var _proteusClientSimulator: ProteusClientSimulator?
    private var _isProteusInitialized = false

    var coreCrypto: SafeCoreCrypto {
        get async throws {
            try await ensureProteusInitialized()
            return _coreCrypto!
        }
    }

    var proteusService: ProteusServiceInterface {
        get async throws {
            try await ensureProteusInitialized()
            return _proteusService!
        }
    }

    var proteusClientSimulator: ProteusClientSimulator {
        get async throws {
            try await ensureProteusInitialized()
            return _proteusClientSimulator!
        }
    }

    let owningDomain = "example.com"

    var useInMemoryStore: Bool {
        true
    }

    var syncMOC: NSManagedObjectContext! {
        coreDataStack.syncContext
    }

    var uiMOC: NSManagedObjectContext! {
        coreDataStack.viewContext
    }

    var eventMOC: NSManagedObjectContext! {
        coreDataStack.eventContext
    }

    override func setUp() async throws {
        try await super.setUp()

        BackgroundActivityFactory.shared.activityManager = UIApplication.shared
        BackgroundActivityFactory.shared.resume()

        // Set up core data stack

        accountIdentifier = UUID()
        try await coreDataStack = createCoreDataStack(
            userIdentifier: accountIdentifier,
            inMemoryStore: useInMemoryStore
        )

        // Caches and timers (lightweight setup)

        await setupCaches(in: coreDataStack)
        await setupTimers()

        // Set up managed objects

        await syncMOC.perform { [self] in
            setupUsersAndClients()
            groupConversation = createGroupConversation(with: otherUser)
            oneToOneConversation = setupOneToOneConversation(with: otherUser)
            oneToOneConnection = otherUser.connection
            syncMOC.saveOrRollback()
        }

        // Note: Proteus/CoreCrypto initialization is now lazy - it will be set up
        // automatically when tests first access proteusService, coreCrypto, or
        // proteusClientSimulator properties
    }

    override func tearDown() async throws {
        BackgroundActivityFactory.shared.activityManager = nil

        await syncMOC.perform { [syncMOC] in
            syncMOC?.proteusService = nil
            self.otherUser = nil
            self.otherClient = nil
            self.selfClient = nil
            self.groupConversation = nil
        }
        await stopEphemeralMessageTimers()

        // Only clean up Proteus if it was initialized
        if _isProteusInitialized {
            _proteusClientSimulator?.cleanup()
            try _coreCrypto?.tearDown()
        }

        _proteusService = nil
        _coreCrypto = nil
        _proteusClientSimulator = nil
        _isProteusInitialized = false
        accountIdentifier = nil
        coreDataStack = nil

        try await super.tearDown()
    }
}

// MARK: - Messages

extension MessagingTestBase {

    func encryptedUpdateEventToSelfFromOtherClient(
        message: GenericMessage,
        conversation: ZMConversation? = nil,
        source: ZMUpdateEventSource = .pushNotification
    ) async throws -> ZMUpdateEvent {
        let cyphertext = try await proteusClientSimulator.encryptedMessageToSelf(
            message: message,
            from: otherClient
        )

        return await syncMOC.perform { [self] in
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
    func outgoingMessageWrapper(
        from request: ZMTransportRequest,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Proteus_NewOtrMessage? {
        guard let data = request.binaryData else {
            XCTFail("No binary data", file: file, line: line)
            return nil
        }
        return try? Proteus_NewOtrMessage(serializedData: data)
    }

    /// Extract encrypted payload from a request
    func outgoingEncryptedMessage(
        from request: ZMTransportRequest,
        for client: UserClient,
        line: UInt = #line,
        file: StaticString = #filePath
    ) async throws -> GenericMessage? {

        guard let data = request.binaryData, let protobuf = try? Proteus_NewOtrMessage(serializedData: data) else {
            XCTFail("No binary data", file: file, line: line)
            return nil
        }

        let userEntries = protobuf.recipients.compactMap(\.self)
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
        guard let plaintext = try await proteusClientSimulator.decryptMessageFromSelf(
            cypherText: clientEntry.text,
            to: otherClient
        ) else {
            XCTFail("failed to decrypt", file: file, line: line)
            return nil
        }

        return try? GenericMessage(serializedData: plaintext)
    }
}

// MARK: - Internal data provisioning

extension MessagingTestBase {

    func setupOneToOneConversation(with user: ZMUser) -> ZMConversation {
        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.domain = owningDomain
        conversation.conversationType = .oneOnOne
        conversation.remoteIdentifier = UUID.create()
        user.connection = ZMConnection.insertNewObject(in: syncMOC)
        user.connection?.status = .accepted
        user.oneOnOneConversation = conversation
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        syncMOC.saveOrRollback()
        return conversation
    }

    /// Creates a user and a client
    func createUser(alsoCreateClient: Bool = false) -> ZMUser {
        createUser(
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
            _ = createClient(
                user: user,
                in: context
            )
        }

        return user
    }

    /// Creates a new client for a user
    func createClient(user: ZMUser) -> UserClient {
        createClient(
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
        createGroupConversation(
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
        createTeam(in: syncMOC)
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

    /// Creates users and clients
    private func setupUsersAndClients() {

        otherUser = createUser(alsoCreateClient: true)
        otherClient = otherUser.clients.first!
        thirdUser = createUser(alsoCreateClient: true)
        selfClient = createSelfClient()
    }

    /// Creates self client and user
    private func createSelfClient() -> UserClient {
        let user = ZMUser.selfUser(in: syncMOC)
        user.remoteIdentifier = UUID.create()
        user.domain = owningDomain

        let selfClient = UserClient.insertNewObject(in: syncMOC)
        selfClient.remoteIdentifier = "baddeed"
        selfClient.user = user

        syncMOC.setPersistentStoreMetadata(selfClient.remoteIdentifier!, key: ZMPersistedClientIdKey)
        selfClient.type = .permanent
        syncMOC.saveOrRollback()
        return selfClient
    }
}

// MARK: - Internal helpers

extension MessagingTestBase {

    func setupTimers() async {
        await syncMOC.perform { [syncMOC] in
            syncMOC.zm_createMessageObfuscationTimer()
        }
        await uiMOC.perform { [uiMOC] in
            uiMOC.zm_createMessageDeletionTimer()
        }
    }

    func stopEphemeralMessageTimers() async {
        await syncMOC.perform { [syncMOC] in
            syncMOC.zm_teardownMessageObfuscationTimer()
        }

        await uiMOC.perform { [uiMOC] in
            uiMOC.zm_teardownMessageDeletionTimer()
        }
    }
}

// MARK: - Contexts

extension MessagingTestBase {

    override var allDispatchGroups: [ZMSDispatchGroup] {
        super.allDispatchGroups + [syncMOC?.dispatchGroup, uiMOC?.dispatchGroup].compactMap(\.self)
    }

    func performPretendingUiMocIsSyncMoc(block: () -> Void) {
        uiMOC.resetContextType()
        uiMOC.markAsSyncContext()
        block()
        uiMOC.resetContextType()
        uiMOC.markAsUIContext()
    }
}

// MARK: - Payload for message

extension MessagingTestBase {
    public func payloadForMessage(
        in conversation: ZMConversation?,
        type: String,
        data: Any
    ) -> NSMutableDictionary? {
        payloadForMessage(in: conversation!, type: type, data: data, time: nil)
    }

    public func payloadForMessage(
        in conversation: ZMConversation,
        type: String,
        data: Any,
        time: Date?
    ) -> NSMutableDictionary? {
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

    public func payloadForMessage(
        in conversation: ZMConversation,
        type: String,
        data: Any,
        time: Date?,
        from: ZMUser
    ) -> NSMutableDictionary? {

        [
            "conversation": conversation.remoteIdentifier?.transportString() ?? "",
            "data": data,
            "from": from.remoteIdentifier.transportString(),
            "time": time?.transportString() ?? "",
            "type": type
        ]
    }

    public func payloadForMessage(
        conversationID: UUID,
        domain: String?,
        type: String,
        data: Any,
        time: Date?,
        fromID: UUID
    ) -> NSMutableDictionary? {

        [
            "conversation": conversationID.transportString(),
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

// MARK: - ProteusService Setup

extension MessagingTestBase {

    /// Ensures Proteus/CoreCrypto is initialized - call this before accessing proteus properties
    private func ensureProteusInitialized() async throws {
        guard !_isProteusInitialized else { return }

        // Set up proteus client simulator
        let cacheFolder = try XCTUnwrap(FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first)
        let storageURL = cacheFolder.appendingPathComponent("OtherClients")
        try? FileManager.default.removeItem(at: storageURL)

        _proteusClientSimulator = ProteusClientSimulator(
            syncMOC: syncMOC,
            owningDomain: owningDomain,
            storageURL: storageURL
        )

        // Set up Proteus service and CoreCrypto
        try await setupProteusService()

        // Establish session after users/clients are created
        if let otherClient {
            try await _proteusClientSimulator!.establishSessionFromSelf(to: otherClient)
        }

        _isProteusInitialized = true
    }

    func setupProteusService() async throws {
        let accountDir = coreDataStack.accountContainer

        let mockKeyMigrationManager = MockCoreCryptoKeyMigrationManagerProtocol()
        mockKeyMigrationManager.isKeyRotationNeeded = false
        mockKeyMigrationManager.isMigrationToBytesNeeded = false
        mockKeyMigrationManager.isMigrationToScopedKeyNeeded = false

        // Create CoreCryptoProvider which handles proper initialization
        let coreCryptoProvider = CoreCryptoProvider(
            selfUserID: accountIdentifier,
            sharedContainerURL: coreDataStack.applicationContainer,
            accountDirectory: accountDir,
            sharedUserDefaults: UserDefaults.standard,
            syncContext: syncMOC,
            coreCryptoKeyMigrationManager: mockKeyMigrationManager,
            allowCreation: true,
            localDomain: owningDomain
        )

        // Initialize CoreCrypto (this calls proteusInit internally)
        _coreCrypto = try await coreCryptoProvider.coreCrypto() as? SafeCoreCrypto

        // Create ProteusService with the provider
        _proteusService = ProteusService(coreCryptoProvider: coreCryptoProvider)

        await syncMOC.perform { [syncMOC, service = self._proteusService] in
            syncMOC.proteusService = service
        }
    }

}
