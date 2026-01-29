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

import CoreLocation
import Foundation
import WireLogging
import WireUtilities

public let ZMUserClientNumberOfKeysRemainingKey = "numberOfKeysRemaining"
public let ZMUserClientNeedsToUpdateCapabilitiesKey = "needsToUpdateCapabilities"

public let ZMUserClientMarkedToDeleteKey = "markedToDelete"
public let ZMUserClientMissingKey = "missingClients"
public let ZMUserClientUserKey = "user"
let ZMUserClientLabelKey = "label"
public let ZMUserClientTrusted_ByKey = "trustedByClients"
public let ZMUserClientIgnored_ByKey = "ignoredByClients"
public let ZMUserClientTrustedKey = "trustedClients"
public let ZMUserClientIgnoredKey = "ignoredClients"
public let ZMUserClientNeedsToNotifyUserKey = "needsToNotifyUser"
public let ZMUserClientFingerprintKey = "fingerprint"
public let ZMUserClientRemoteIdentifierKey = "remoteIdentifier"
public let ZMUserClientNeedsToNotifyOtherUserAboutSessionResetKey = "needsToNotifyOtherUserAboutSessionReset"

private let zmLog = ZMSLog(tag: "UserClient")

@objcMembers
public class UserClient: ZMManagedObject, UserClientType {

    @NSManaged public var type: DeviceType
    @NSManaged public var label: String?
    @NSManaged public var markedToDelete: Bool
    @NSManaged public var preKeysRangeMax: Int64
    @NSManaged public var remoteIdentifier: String?
    @NSManaged public var user: ZMUser?
    @NSManaged public var missingClients: Set<UserClient>?
    @NSManaged public var missedByClient: UserClient?
    @NSManaged public var addedOrRemovedInSystemMessages: Set<ZMSystemMessage>
    @NSManaged public var messagesMissingRecipient: Set<ZMMessage>
    @NSManaged public var numberOfKeysRemaining: Int32
    @NSManaged public var activationDate: Date?
    @NSManaged public var discoveryDate: Date?
    @NSManaged public var lastActiveDate: Date?
    @NSManaged public var model: String?
    @NSManaged public var deviceClass: DeviceClass?
    @NSManaged public var needsToNotifyUser: Bool
    @NSManaged public var needsToUpdateCapabilities: Bool
    @NSManaged public var needsToNotifyOtherUserAboutSessionReset: Bool
    @NSManaged public var needsSessionMigration: Bool
    @NSManaged public var discoveredByMessage: ZMOTRMessage?

    /// Client has the capability to use new `consumable-notifications` synchronization system (v8+)
    @NSManaged public var isConsumableNotificationsCapable: Bool

    /// Clients that are trusted by self client.
    @NSManaged public var trustedClients: Set<UserClient>

    /// Clients that trust this client (currently can contain only self client)
    @NSManaged public var trustedByClients: Set<UserClient>

    /// Clients which trust is ignored by user
    @NSManaged public var ignoredClients: Set<UserClient>

    /// Clients that ignore this client trust (currently can contain only self client)
    @NSManaged public var ignoredByClients: Set<UserClient>

    public var e2eIdentityCertificate: E2eIdentityCertificate? {
        didSet {
            NotificationCenter.default.post(name: .e2eiCertificateChanged, object: self)
        }
    }

    public var mlsThumbPrint: String?

    public var isLegalHoldDevice: Bool {
        deviceClass == .legalHold || type == .legalHold
    }

    public var verified: Bool {
        guard
            let managedObjectContext,
            let selfClient = ZMUser.selfUser(in: managedObjectContext).selfClient()
        else { return false }
        return selfClient.remoteIdentifier == remoteIdentifier || selfClient.trustedClients.contains(self)
    }

    public override static func entityName() -> String {
        "UserClient"
    }

    public override func keysTrackedForLocalModifications() -> Set<String> {
        [
            ZMUserClientMarkedToDeleteKey,
            ZMUserClientNumberOfKeysRemainingKey,
            ZMUserClientMissingKey,
            ZMUserClientNeedsToUpdateCapabilitiesKey,
            UserClient.needsToUploadMLSPublicKeysKey
        ]
    }

    public override static func sortKey() -> String {
        ZMUserClientLabelKey
    }

    public override static func predicateForObjectsThatNeedToBeInsertedUpstream() -> NSPredicate? {
        NSPredicate(format: "%K == NULL", ZMUserClientRemoteIdentifierKey)
    }

    public override static func predicateForObjectsThatNeedToBeUpdatedUpstream() -> NSPredicate? {
        let baseModifiedPredicate = super.predicateForObjectsThatNeedToBeUpdatedUpstream()
        let remoteIdentifierPresentPredicate = NSPredicate(format: "\(ZMUserClientRemoteIdentifierKey) != nil")
        let notDeletedPredicate = NSPredicate(format: "\(ZMUserClientMarkedToDeleteKey) == NO")

        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            baseModifiedPredicate!,
            notDeletedPredicate,
            remoteIdentifierPresentPredicate
        ])
    }

    /// Insert a new client of the local self user.

    @discardableResult
    @objc(insertNewSelfClientInManagedObjectContext:selfUser:model:label:)
    public static func insertNewSelfClient(
        in managedObjectContext: NSManagedObjectContext,
        selfUser: ZMUser,
        model: String,
        label: String
    ) -> UserClient {
        WireLogger.userClient.debug("inserting new self client in context \(managedObjectContext)")

        let userClient = UserClient.insertNewObject(in: managedObjectContext)
        userClient.user = selfUser
        userClient.model = model
        userClient.label = label
        userClient.type = .permanent
        userClient.deviceClass = model.hasPrefix("iPad") ? .tablet : .phone

        return userClient
    }

    public func markAsSelfClient() {
        guard let context = managedObjectContext else { return }
        context.setPersistentStoreMetadata(remoteIdentifier, key: ZMPersistedClientIdKey)
        _ = context.makeMetadataPersistent()
    }

    public static func fetchUserClient(
        withRemoteId remoteIdentifier: String,
        forUser user: ZMUser,
        createIfNeeded: Bool
    ) -> UserClient? {
        precondition(
            !createIfNeeded || user.managedObjectContext!.zm_isSyncContext,
            "clients can only be created on the syncContext"
        )

        guard let context = user.managedObjectContext else {
            fatal(
                "User \(user.safeForLoggingDescription) is not a member of a managed object context (deleted object)."
            )
        }

        let relationClients = user.clients.filter { $0.remoteIdentifier == remoteIdentifier }

        if relationClients.count > 1 {
            WireLogger.userClient.error("Detected duplicate clients: \(relationClients.map(\.remoteIdentifier))")
        }

        requireInternal(
            relationClients.count <= 1,
            "Detected duplicate clients: \(relationClients.map(\.safeForLoggingDescription))"
        )

        if let client = relationClients.first {
            return client
        }

        if let client = fetchExistingUserClient(with: remoteIdentifier, in: context) {
            // We already checked the user's client list but didn't find the client.
            // But we did find the client in the database, so the user is out of date
            // and needs to be refreshed.
            context.refresh(user, mergeChanges: true)
            return client
        }

        if createIfNeeded {
            WireLogger.userClient.info("inserting new user client (\(remoteIdentifier)) in context \(context)")

            let newClient = UserClient.insertNewObject(in: context)
            newClient.remoteIdentifier = remoteIdentifier
            newClient.user = user
            newClient.needsToBeUpdatedFromBackend = true
            newClient.discoveryDate = Date()
            newClient.needsSessionMigration = user.domain == nil
            // Form reverse relationship
            user.mutableSetValue(forKey: "clients").add(newClient)
            return newClient
        }

        return nil
    }

    /// Update a user client with a backend payload
    ///
    /// If called on a client belonging to the self user this method does nothing.

    public func update(with payload: [String: Any]) {
        needsToBeUpdatedFromBackend = false

        guard user?.isSelfUser == false, let deviceClass = payload["class"] as? String else { return }

        self.deviceClass = DeviceClass(rawValue: deviceClass)
    }

    /// Resets releationships and ends an exisiting session before deleting the object
    public func deleteClientAndEndSession() async {
        do {
            try await deleteSession()
        } catch {
            WireLogger.userClient.error("error deleting session: \(String(reflecting: error))")
        }
        await managedObjectContext?.perform { self.deleteClient() }
    }

    private func deleteClient() {
        guard let managedObjectContext else { return }

        assert(managedObjectContext.zm_isSyncContext, "clients can only be deleted on syncContext")
        // hold on to the conversations that are affected by removing this client
        let conversations = activeConversationsForUserOfClients([self])
        let user = user

        failedToEstablishSession = false

        // reset the relationship
        self.user = nil

        if let previousUser = user {
            // increase securityLevel of affected conversations
            if isLegalHoldDevice, previousUser.isSelfUser {
                previousUser.needsToAcknowledgeLegalHoldStatus = true
            }

            conversations.forEach { $0.increaseSecurityLevelIfNeededAfterRemoving(clients: [previousUser: [self]]) }

            // if they have no clients left, it's possible they left the team
            let userMayHaveLeftTeam = previousUser.isTeamMember && previousUser.clients.isEmpty

            if userMayHaveLeftTeam {
                previousUser.needsToBeUpdatedFromBackend = true
            }
        }

        // delete the object
        managedObjectContext.delete(self)
    }

    /// Checks if there is an existing session with the self client.
    ///
    /// Note: only access this property only from the sync context.

    public var hasSessionWithSelfClient: Bool {
        get async {
            guard
                let sessionID = await managedObjectContext?.perform({ self.proteusSessionID }),
                let proteusService = await managedObjectContext?
                .perform({ [managedObjectContext] in managedObjectContext?.proteusService })
            else {
                return false
            }

            return await proteusService.sessionExists(id: sessionID)
        }
    }

    /// Resets the session between the client and the selfClient
    /// Can be called several times without issues

    public func resetSession() {
        guard
            let uiMOC = managedObjectContext?.zm_userInterface,
            let syncMOC = uiMOC.zm_sync
        else {
            return
        }

        WaitingGroupTask(context: syncMOC) {
            guard let syncClient = await syncMOC.perform({
                (try? syncMOC.existingObject(with: self.objectID)) as? UserClient
            }) else {
                return
            }

            // Delete session and fingerprint
            try? await syncClient.deleteSession()

            await syncMOC.perform {
                // Mark that we need notify the other party about the session reset
                syncClient.needsToNotifyOtherUserAboutSessionReset = true

                syncMOC.saveOrRollback()
            }
        }
    }

    public func resolveDecryptionFailedSystemMessages() {
        let request = NSBatchUpdateRequest(entityName: ZMSystemMessage.entityName())

        request.predicate = NSPredicate(
            format: "%K = %d AND %K = %@",
            ZMMessageSystemMessageTypeKey,
            ZMSystemMessageType.decryptionFailed.rawValue,
            ZMMessageSenderClientIDKey,
            remoteIdentifier!
        )
        request
            .propertiesToUpdate = [ZMMessageSystemMessageTypeKey: ZMSystemMessageType.decryptionFailedResolved.rawValue]
        request.resultType = .updatedObjectIDsResultType
        managedObjectContext?.executeBatchUpdateRequestOrAssert(request)
    }

    private func conversation(for user: ZMUser) -> ZMConversation? {
        if user.isSelfUser {
            guard let moc = user.managedObjectContext else { return nil }
            return ZMConversation.selfConversation(in: moc)
        } else {
            return user.oneToOneConversation
        }
    }

}

// MARK: - SelfUser client methods (selfClient + other clients of the selfUser)

public extension UserClient {

    @objc
    static func fetchExistingUserClient(
        with remoteIdentifier: String,
        in context: NSManagedObjectContext
    ) -> UserClient? {
        let fetchRequest = NSFetchRequest<UserClient>(entityName: UserClient.entityName())
        fetchRequest.predicate = NSPredicate(format: "%K == %@", ZMUserClientRemoteIdentifierKey, remoteIdentifier)
        fetchRequest.fetchLimit = 1

        return context.fetchOrAssert(request: fetchRequest).first
    }

    static func fetchClientsNeedingUpdateFromBackend(in context: NSManagedObjectContext) -> [UserClient] {
        let fetchRequest = NSFetchRequest<UserClient>(entityName: UserClient.entityName())
        fetchRequest.predicate = NSPredicate(format: "%K == YES", #keyPath(UserClient.needsToBeUpdatedFromBackend))
        return context.fetchOrAssert(request: fetchRequest)
    }

    /// Use this method only for selfUser clients (selfClient + remote clients)
    @objc
    static func createOrUpdateSelfUserClient(
        _ payloadData: [String: AnyObject],
        context: NSManagedObjectContext
    ) -> UserClient? {
        WireLogger.userClient.info("create or update self user client")

        guard
            let id = payloadData["id"] as? String,
            let type = payloadData["type"] as? String
        else {
            return nil
        }

        let payloadAsDictionary = payloadData as NSDictionary

        let label = payloadAsDictionary.optionalString(forKey: "label")?.removingExtremeCombiningCharacters
        let model = payloadAsDictionary.optionalString(forKey: "model")?.removingExtremeCombiningCharacters
        let deviceClass = payloadAsDictionary.optionalString(forKey: "class")
        let activationDate = payloadAsDictionary.date(for: "time")
        let lastActiveDate = payloadAsDictionary.optionalDate(forKey: "last_active")
        let result = fetchOrCreateUserClient(with: id, in: context)
        let client = result.client
        let isNewClient = result.isNewClient
        let mlsPublicKeys = payloadAsDictionary.optionalDictionary(forKey: "mls_public_keys")
        let mlsEd25519 = mlsPublicKeys?.optionalString(forKey: "ed25519")
        let mlsEd448 = mlsPublicKeys?.optionalString(forKey: "ed448")
        let mlsP256 = mlsPublicKeys?.optionalString(forKey: "ecdsa_secp256r1_sha256")
        let mlsP384 = mlsPublicKeys?.optionalString(forKey: "ecdsa_secp384r1_sha384")
        let mlsP521 = mlsPublicKeys?.optionalString(forKey: "ecdsa_secp521r1_sha512")

        client.label = label
        client.type = DeviceType(rawValue: type)
        client.model = model
        client.deviceClass = deviceClass.map { DeviceClass(rawValue: $0) }
        client.activationDate = activationDate
        client.lastActiveDate = lastActiveDate
        client.remoteIdentifier = id
        if let capabilities = payloadAsDictionary.optionalArray(forKey: "capabilities") as? [String] {
            client.isConsumableNotificationsCapable = capabilities.contains("consumable-notifications")
        }

        let selfUser = ZMUser.selfUser(in: context)
        client.user = client.user ?? selfUser

        if isNewClient {
            client.needsSessionMigration = selfUser.domain == nil
        }

        if client.isLegalHoldDevice, isNewClient {
            selfUser.legalHoldRequest = nil
            selfUser.needsToAcknowledgeLegalHoldStatus = true
        }

        if !client.isSelfClient() {
            client.mlsPublicKeys = MLSPublicKeys(
                ed25519: mlsEd25519,
                ed448: mlsEd448,
                p256: mlsP256,
                p384: mlsP384,
                p521: mlsP521
            )
        }

        if let selfClient = selfUser.selfClient() {
            if client.remoteIdentifier != selfClient.remoteIdentifier, isNewClient {

                if let selfClientActivationdate = selfClient.activationDate,
                   client.activationDate?.compare(selfClientActivationdate) == .orderedDescending {
                    // swiftlint:disable:next todo_requires_jira_link
                    // TODO: Check this flag

                    client.needsToNotifyUser = true
                }
            }
        }

        return client

    }

    private static func fetchOrCreateUserClient(
        with id: String,
        in context: NSManagedObjectContext
    ) -> (client: UserClient, isNewClient: Bool) {
        var client: UserClient
        var isNewClient: Bool

        WireLogger.userClient.info("trying to fetch client with id (\(id))")
        // swiftlint:disable:next todo_requires_jira_link
        // TODO: could optimize: look into self user relationship before executing a fetch request
        if let fetchedClient = fetchExistingUserClient(with: id, in: context) {
            WireLogger.userClient.info("fetched existing user client in context \(context)")
            client = fetchedClient
            isNewClient = false
        } else {
            WireLogger.userClient.info("no fetched client. inserting new user client in context \(context)")
            client = UserClient.insertNewObject(in: context)
            isNewClient = true
        }

        return (client, isNewClient)
    }

    /// Use this method only for selfUser clients (selfClient + remote clients)
    @objc
    func markForDeletion() {
        guard let context = managedObjectContext else {
            zmLog.error("Object already deleted?")
            return
        }
        let selfUser = ZMUser.selfUser(in: context)
        guard user == selfUser else {
            fatal(
                "The method 'markForDeletion()' can only be called for clients that belong to the selfUser (self user is \(selfUser.safeForLoggingDescription))"
            )
        }
        guard selfUser.selfClient() != self else {
            fatal("Attempt to delete the self client. This should never happen!")
        }
        markedToDelete = true
        setLocallyModifiedKeys([ZMUserClientMarkedToDeleteKey])
    }
}

// MARK: - Corrupted Session

public extension UserClient {

    @objc var failedToEstablishSession: Bool {
        get {
            managedObjectContext?.zm_failedToEstablishSessionStore?.contains(self) ?? false
        }
        set {
            if newValue {
                managedObjectContext?.zm_failedToEstablishSessionStore?.add(self)
            } else {
                managedObjectContext?.zm_failedToEstablishSessionStore?.remove(self)
            }
        }

    }
}

// MARK: - SelfClient methods

public extension UserClient {

    @objc
    func isSelfClient() -> Bool {
        guard let managedObjectContext,
              let selfClient = ZMUser.selfUser(in: managedObjectContext).selfClient()
        else { return false }
        return self == selfClient
    }

    @objc
    func missesClient(_ client: UserClient) {
        missesClients([client])
    }

    @objc
    func missesClients(_ clients: Set<UserClient>) {

        zmLog.debug("Adding clients(\(clients.count)) to list of missing clients")

        mutableSetValue(forKey: ZMUserClientMissingKey).union(clients)
        if !hasLocalModifications(forKey: ZMUserClientMissingKey) {
            setLocallyModifiedKeys([ZMUserClientMissingKey])
        }
    }

    /// Use this method only for the selfClient
    @objc
    func removeMissingClient(_ client: UserClient) {
        zmLog.debug("Removing client from list of missing clients")

        mutableSetValue(forKey: ZMUserClientMissingKey).remove(client)
    }

    /// Deletes the session between the selfClient and the given userClient
    /// If there is no session it does nothing
    func deleteSession() async throws {
        guard
            let context = managedObjectContext,
            await context.perform({ !self.isSelfClient() }),
            let sessionID = await context.perform({ self.proteusSessionID }),
            let proteusService = await context.perform({ context.proteusService })
        else {
            return
        }
        try await proteusService.deleteSession(id: sessionID)
    }

    func establishSessionWithClient(
        _ client: UserClient,
        usingPreKey preKey: String
    ) async -> Bool {
        guard
            let context = managedObjectContext,
            let proteusService = await context.perform({ context.proteusService }),
            let sessionId = await context.perform({ client.proteusSessionID })
        else {
            return false
        }

        do {
            // swiftlint:disable:next todo_requires_jira_link
            // TODO: check if we should delete session if it exists before creating new one

            try await proteusService.establishSession(id: sessionId, fromPrekey: preKey)
            return true
        } catch {
            zmLog.error("Cannot create session for prekey \(preKey): \(String(describing: error))")
            return false
        }
    }

    /// Use this method only for the selfClient
    @objc
    func decrementNumberOfRemainingProteusKeys() {
        guard isSelfClient() else {
            fatal("`decrementNumberOfRemainingProteusKeys` should only be called on the self client")
        }

        if numberOfKeysRemaining > 0 {
            numberOfKeysRemaining -= 1
        }

        // this will recover from the fact that the number might already be < 0 from a previous run
        if numberOfKeysRemaining < 0 {
            numberOfKeysRemaining = 0
        }

        if numberOfKeysRemaining == 0 {
            setLocallyModifiedKeys([ZMUserClientNumberOfKeysRemainingKey])
        }
    }
}

enum SecurityChangeType {
    case clientTrusted // a client was trusted by the user on this device
    case clientDiscovered // a client was discovered, either by receiving a missing response, a message, or fetching all
    // clients
    case clientIgnored // a client was ignored by the user on this device

    func changeSecurityLevel(_ conversation: ZMConversation, clients: Set<UserClient>, causedBy: ZMOTRMessage?) {
        switch self {
        case .clientTrusted:
            conversation.increaseSecurityLevelIfNeededAfterTrusting(clients: clients)
        case .clientIgnored:
            conversation.decreaseSecurityLevelIfNeededAfterIgnoring(clients: clients)
        case .clientDiscovered:
            conversation.decreaseSecurityLevelIfNeededAfterDiscovering(clients: clients, causedBy: causedBy)
        }
    }
}

// MARK: - Trusting

public extension UserClient {

    @objc
    func trustClient(_ client: UserClient) {
        trustClients([client])
    }

    /// Will change conversations security level as side effect
    @objc
    func trustClients(_ clients: Set<UserClient>) {
        guard !clients.isEmpty else { return }
        mutableSetValue(forKey: ZMUserClientIgnoredKey).minus(clients)
        mutableSetValue(forKey: ZMUserClientTrustedKey).union(clients)

        clients.forEach { client in client.needsToNotifyUser = false }

        zmLog.debug("Marking client as trusted")

        changeSecurityLevel(.clientTrusted, clients: clients, causedBy: nil)
    }

    /// Ignore a know client
    @objc
    func ignoreClient(_ client: UserClient) {
        ignoreClients([client])
    }

    /// Adds to ignored clients, remove from trusted clients, returns the set with the self client excluded
    private func addIgnoredClients(_ clients: Set<UserClient>) -> Set<UserClient> {
        let notSelfClients = Set(clients.filter { $0 != self })

        guard !notSelfClients.isEmpty else { return notSelfClients }

        zmLog.debug("Marking client as ignored")

        mutableSetValue(forKey: ZMUserClientTrustedKey).minus(notSelfClients)
        mutableSetValue(forKey: ZMUserClientIgnoredKey).union(notSelfClients)

        return notSelfClients
    }

    /// Ignore known clients
    @objc
    func ignoreClients(_ clients: Set<UserClient>) {
        let notSelfClients = addIgnoredClients(clients)
        guard !notSelfClients.isEmpty else { return }
        changeSecurityLevel(.clientIgnored, clients: notSelfClients, causedBy: .none)
    }

    /// Adds a new client that was just discovered to the ignored ones
    @objc
    func addNewClientToIgnored(_ client: UserClient) {
        addNewClientsToIgnored([client])
    }

    /// Add new clients that were just discovered to the ignored ones
    @objc
    func addNewClientsToIgnored(_ clients: Set<UserClient>) {
        _ = addIgnoredClients(clients)

    }

    func updateSecurityLevelAfterDiscovering(_ clients: Set<UserClient>) {
        changeSecurityLevel(
            .clientDiscovered,
            clients: clients,
            causedBy: clients.compactMap(\.discoveredByMessage).first
        )
    }

    internal func activeConversationsForUserOfClients(_ clients: Set<UserClient>) -> Set<ZMConversation> {
        clients.map(\.user).reduce(into: []) {
            guard let user = $1 else {
                return
            }

            if user.isSelfUser {
                let predicateFactory = ConversationPredicateFactory(selfTeam: user.team)
                let fetchRequest = NSFetchRequest<ZMConversation>(entityName: ZMConversation.entityName())
                fetchRequest.predicate = predicateFactory.predicateForConversationsIncludingArchived()
                let conversations = managedObjectContext?.fetchOrAssert(request: fetchRequest) ?? []
                return $0.formUnion(conversations)
            } else {
                return $0.formUnion(user.participantRoles.compactMap(\.conversation))
            }
        }
    }

    internal func changeSecurityLevel(
        _ securityChangeType: SecurityChangeType,
        clients: Set<UserClient>,
        causedBy: ZMOTRMessage?
    ) {
        let conversations = activeConversationsForUserOfClients(clients)
        conversations.forEach { conversation in
            if !conversation.isReadOnly {
                let clientsInConversation = clients.filter { client in
                    guard let user = client.user else { return false }
                    return conversation.localParticipants.contains(user)
                }
                securityChangeType.changeSecurityLevel(
                    conversation,
                    clients: Set(clientsInConversation),
                    causedBy: causedBy
                )
            }
        }
    }
}

// MARK: - Update SelfClient Capability

public extension UserClient {

    static func triggerSelfClientCapabilityUpdate(_ context: NSManagedObjectContext) {
        guard let selfClient = ZMUser.selfUser(in: context).selfClient() else { return }

        selfClient.needsToUpdateCapabilities = true
        selfClient.setLocallyModifiedKeys([ZMUserClientNeedsToUpdateCapabilitiesKey])

        context.enqueueDelayedSave()
    }

}

// MARK: - Proteus Session ID

extension UserClient {

    public var proteusSessionID: ProteusSessionID? {
        if needsSessionMigration {
            proteusSessionID_V2
        } else {
            proteusSessionID_V3
        }
    }

    private var proteusSessionID_V2: ProteusSessionID? {
        guard
            let userID = user?.remoteIdentifier,
            let clientID = remoteIdentifier
        else {
            return nil
        }

        return ProteusSessionID(
            userID: userID.uuidString,
            clientID: clientID
        )
    }

    private var proteusSessionID_V3: ProteusSessionID? {
        guard
            let user,
            let domain = user.domain ?? managedObjectContext?.localDomain,
            let userID = user.remoteIdentifier,
            let clientID = remoteIdentifier
        else {
            return nil
        }

        return ProteusSessionID(
            domain: domain,
            userID: userID.uuidString,
            clientID: clientID
        )
    }

}
