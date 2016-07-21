// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import Cryptobox
import CoreLocation
import ZMUtilities

public let ZMUserClientNumberOfKeysRemainingKey = "numberOfKeysRemaining"
public let ZMUserClientNeedsToUpdateSignalingKeysKey = "needsToUploadSignalingKeys"

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

private let zmLog = ZMSLog(tag: "UserClient")

@objc(UserClient)
public class UserClient: ZMManagedObject, UserClientType {
    
    @NSManaged public var type: String //default value is ZMUserClientTypePermanent
    @NSManaged public var label: String?
    @NSManaged public var markedToDelete: Bool
    @NSManaged public var preKeysRangeMax: Int64
    @NSManaged public var remoteIdentifier: String!
    @NSManaged public var user: ZMUser?
    @NSManaged public var missingClients: Set<UserClient>?
    @NSManaged private var missedByClient: UserClient?
    @NSManaged private var addedOrRemovedInSystemMessages: Set<ZMSystemMessage>?
    @NSManaged public var messagesMissingRecipient: Set<ZMMessage>?
    @NSManaged public var numberOfKeysRemaining: Int32
    @NSManaged public var activationAddress: String?
    @NSManaged public var activationDate: NSDate?
    @NSManaged public var model: String?
    @NSManaged public var deviceClass: String?
    @NSManaged public var activationLocationLatitude: Double
    @NSManaged public var activationLocationLongitude: Double
    @NSManaged public var needsToNotifyUser: Bool
    @NSManaged public var fingerprint: NSData?
    @NSManaged public var apsVerificationKey: NSData?
    @NSManaged public var apsDecryptionKey: NSData?
    @NSManaged public var needsToUploadSignalingKeys: Bool

    /// Clients that are trusted by self client.
    @NSManaged public var trustedClients: Set<UserClient>
    
    /// Clients that trust this client (currently can contain only self client)
    @NSManaged public var trustedByClients: Set<UserClient>
    
    /// Clients which trust is ignored by user
    @NSManaged public var ignoredClients: Set<UserClient>
    
    /// Clients that ignore this client trust (currently can contain only self client)
    @NSManaged public var ignoredByClients: Set<UserClient>
    
    public var keysStore: UserClientKeysStore {
        return managedObjectContext!.zm_cryptKeyStore
    }
    
    public var activationLocation: CLLocation {
        return CLLocation(latitude: self.activationLocationLatitude, longitude: self.activationLocationLongitude)
    }
    
    public override func awakeFromFetch() {
        super.awakeFromFetch()
        
        // Fetch fingerprint if not there yet (could remain nil after fetch)
        if let managedObjectContext = self.managedObjectContext,
            let _ = self.remoteIdentifier
            where managedObjectContext.zm_isSyncContext && self.fingerprint == .None
        {
            self.fingerprint = self.fetchFingerprint()
        }
    }
    
    public var verified: Bool {
        let selfUser = ZMUser.selfUserInContext(self.managedObjectContext!)
        guard let selfClient = selfUser.selfClient()
            else { return false }
        return selfClient.remoteIdentifier == self.remoteIdentifier || selfClient.trustedClients.contains(self)
    }
    
    public override static func entityName() -> String! {
        return "UserClient"
    }

    public override func keysTrackedForLocalModifications() -> [AnyObject]! {
        return [ZMUserClientMarkedToDeleteKey, ZMUserClientNumberOfKeysRemainingKey, ZMUserClientMissingKey, ZMUserClientNeedsToUpdateSignalingKeysKey]
    }
    
    public override static func sortKey() -> String {
        return ZMUserClientLabelKey
    }
    
    public override static func predicateForObjectsThatNeedToBeInsertedUpstream() -> NSPredicate {
        return NSPredicate(format: "%K == NULL", ZMUserClientRemoteIdentifierKey)
    }
    
    public static func fetchUserClient(withRemoteId remoteIdentifier: String, forUser user:ZMUser, createIfNeeded: Bool) -> UserClient? {
        
        guard let client = user.clients.filter({$0.remoteIdentifier == remoteIdentifier}).first
        else {
            if (createIfNeeded) {
                let newClient = UserClient.insertNewObjectInManagedObjectContext(user.managedObjectContext)
                newClient.remoteIdentifier = remoteIdentifier
                newClient.user = user
                return newClient
            }
            return nil
        }
        return client
    }

    /// Resets releationships and ends an exisiting session before deleting the object
    /// Call this from the syncMOC only
    public func deleteClientAndEndSession() {
        assert(self.managedObjectContext!.zm_isSyncContext, "clients can only be deleted on syncContext")
        // hold on to the conversations that are affected by removing this client
        let conversations = activeConversationsForUserOfClients(Set(arrayLiteral: self))
        let user = self.user
        
        self.failedToEstablishSession = false
        // reset the relationship
        self.user = nil
        // reset the session
        if let remoteIdentifier = remoteIdentifier {
            UserClient.deleteSession(forClientWithRemoteIdentifier: remoteIdentifier, managedObjectContext: managedObjectContext!)
        }
        // delete the object
        managedObjectContext?.deleteObject(self)
        
        // increase securityLevel of affected conversations
        conversations.forEach{$0.increaseSecurityLevelIfNeededAfterRemovingClientForUser(user)}
    }
    
    /// Checks if there is an existing session with the selfClient
    /// Access this property only from the syncContext
    public var hasSessionWithSelfClient: Bool {
        guard let selfClient = ZMUser.selfUserInContext(managedObjectContext!).selfClient()
            else {
                zmLog.error("SelfUser has no selfClient")
                return false
        }
        let session = try? selfClient.keysStore.box.sessionById(self.remoteIdentifier)
        return (session != nil)
    }
    
    /// Resets the session between the client and the selfClient
    /// Can be called several times without issues
    public func resetSession() {
        // Delete should happen on sync context since the cryptobox could be accessed only from there
        UserClient.deleteSession(forClientWithRemoteIdentifier: self.remoteIdentifier, managedObjectContext: (self.managedObjectContext?.zm_syncContext)!)
        
        self.fingerprint = .None
        let selfUser = ZMUser.selfUserInContext(self.managedObjectContext!)
        guard let selfClient = selfUser.selfClient()
            else { return }
        
        selfClient.missesClient(self)
        selfClient.setLocallyModifiedKeys(Set(arrayLiteral: ZMUserClientMissingKey))
        
        // Send session reset message so other user can send us messages immediately
        if let user = self.user {
            let conversation = user.isSelfUser ? ZMConversation.selfConversationInContext(managedObjectContext) : self.user?.oneToOneConversation
            conversation.appendOTRSessionResetMessage()
        }
        
        self.managedObjectContext?.saveOrRollback()
    }
}



// MARK SelfUser client methods  (selfClient + other clients of the selfUser)
public extension UserClient {

    /// Use this method only for selfUser clients (selfClient + remote clients)
    public static func createOrUpdateClient(payloadData: [String: AnyObject], context: NSManagedObjectContext) -> UserClient? {
        if let id = payloadData["id"] as? String,
            type = payloadData["type"] as? String {
                
                let payloadAsDictionary = payloadData as NSDictionary
                
                let label = payloadAsDictionary.optionalStringForKey("label")
                let activationAddress = payloadAsDictionary.optionalStringForKey("address")
                let model = payloadAsDictionary.optionalStringForKey("model")
                let deviceClass = payloadAsDictionary.optionalStringForKey("class")
                let activationDate = payloadAsDictionary.dateForKey("time")
                
                let locationCoordinates = payloadData["location"] as? [String: Double]
                let latitude = (locationCoordinates?["lat"] as Double?) ?? 0
                let longitude = (locationCoordinates?["lon"] as Double?) ?? 0
                
                // TODO: could optimize: look into self user relationship before executing a fetch request
                let fetchRequest = NSFetchRequest(entityName: UserClient.entityName())
                fetchRequest.predicate = NSPredicate(format: "%K == %@", ZMUserClientRemoteIdentifierKey, id)
                fetchRequest.fetchLimit = 1
                let fetchedClient = context.executeFetchRequestOrAssert(fetchRequest).first as? UserClient
                let client: UserClient = fetchedClient != .None ? fetchedClient : UserClient.insertNewObjectInManagedObjectContext(context)
                
               
                client.label = label
                client.type = type
                client.activationAddress = activationAddress
                client.model = model
                client.deviceClass = deviceClass
                client.activationDate = activationDate
                client.activationLocationLatitude = latitude
                client.activationLocationLongitude = longitude
                client.remoteIdentifier = id
                
                if let selfClient = ZMUser.selfUserInContext(context).selfClient() {
                    if client.remoteIdentifier != selfClient.remoteIdentifier &&
                          fetchedClient == .None
                    {
                        client.markForFetchingPreKeys()
                        
                        if let selfClientActivationdate = selfClient.activationDate where client.activationDate?.compare(selfClientActivationdate) == .OrderedDescending {
                            client.needsToNotifyUser = true
                        }
                    }
                    
                    // We could already set local fingerprint if user is self
                    if client.remoteIdentifier == selfClient.remoteIdentifier {
                        do {
                            client.fingerprint = try client.keysStore.box.localFingerprint()
                        }
                        catch let error as NSError {
                            zmLog.error("Cannot fetch local fingerprint for \(client): \(error)")
                        }
                    }
                }
                
                return client
        }
        return nil
    }

    /// Use this method only for selfUser clients (selfClient + remote clients)
    public func markForDeletion() {
        guard let context = self.managedObjectContext else {
            zmLog.error("Object already deleted?")
            return
        }
        let selfUser = ZMUser.selfUserInContext(context)
        guard self.user == selfUser else {
            fatal("The method 'markForDeletion()' can only be called for clients that belong to the selfUser (self user is \(selfUser))")
        }
        guard selfUser.selfClient() != self else {
            fatal("Attempt to delete the self client. This should never happen!")
        }
        self.markedToDelete = true
        self.setLocallyModifiedKeys(Set(arrayLiteral: ZMUserClientMarkedToDeleteKey))
    }
    
    public func markForFetchingPreKeys() {
        if let managedObjectContext = self.managedObjectContext,
            let selfClient = ZMUser.selfUserInContext(managedObjectContext).selfClient()
            where self.fingerprint == .None
        {
            if selfClient.remoteIdentifier == self.remoteIdentifier {
                
                let selfClientObjectID = selfClient.objectID
                
                if let syncManagedObjectContext = self.managedObjectContext?.zm_syncContext {
                    syncManagedObjectContext.performGroupedBlock({ [unowned syncManagedObjectContext] () -> Void in
                        
                        do {
                            let syncClient = try syncManagedObjectContext.existingObjectWithID(selfClientObjectID)
                            
                            if let syncClient = syncClient as? UserClient {
                                syncClient.fingerprint = try syncClient.keysStore.box.localFingerprint()
                                syncManagedObjectContext.saveOrRollback()
                            }
                        }
                        catch let error as NSError {
                            zmLog.error("Cannot fetch local fingerprint: \(error)")
                        }
                    })
                }
            }
            else {
                selfClient.missesClient(self)
                selfClient.setLocallyModifiedKeys(Set(arrayLiteral: ZMUserClientMissingKey))
            }
        }
    }
}


// MARK: - Corrupted Session

public extension UserClient {
    
    public var failedToEstablishSession: Bool {
        set {
            if newValue {
                managedObjectContext?.zm_failedToEstablishSessionStore.addObject(self)
            } else {
                managedObjectContext?.zm_failedToEstablishSessionStore.removeObject(self)
            }
        }
        
        get {
            return managedObjectContext?.zm_failedToEstablishSessionStore.contains(self) ?? false
        }
    }
}


// MARK: SelfClient methods
public extension UserClient {
    
    public func missesClient(client: UserClient) {
        missesClients(Set(arrayLiteral: client))
    }
    
    public func missesClients(clients: Set<UserClient>) {

        self.mutableSetValueForKey(ZMUserClientMissingKey).unionSet(clients)
        if !hasLocalModificationsForKey(ZMUserClientMissingKey) {
            setLocallyModifiedKeys(Set(arrayLiteral: ZMUserClientMissingKey))
        }
    }
    
    /// Use this method only for the selfClient
    public func removeMissingClient(client: UserClient) {
        self.mutableSetValueForKey(ZMUserClientMissingKey).removeObject(client)
    }
    
    /// Deletes the session between the selfClient and the given userClient
    /// If there is no session it does nothing
    static func deleteSession(forClientWithRemoteIdentifier clientID: String, managedObjectContext: NSManagedObjectContext) {
        guard let selfClient = ZMUser.selfUserInContext(managedObjectContext).selfClient() where selfClient.remoteIdentifier != clientID
        else { return }
        do {
            try selfClient.keysStore.box.deleteSessionWithId(clientID)
        }
        catch let error as NSError {
            zmLog.error("Error deleting session with UserClient \(clientID): \(error)")
        }
    }
    
    /// Creates a session between the selfClient and the given userClient
    /// Returns false if the session could not be established
    /// Use this method only for the selfClient
    func establishSessionWithClient(client: UserClient, usingPreKey preKey: String) -> Bool {
        guard let managedObjectContext = self.managedObjectContext else {
            return false
        }
        
        let existingSession = try? keysStore.box.sessionById(client.remoteIdentifier)
        if existingSession != nil {
            _ = try? keysStore.box.deleteSessionWithId(client.remoteIdentifier)
        }
        
        let selfClient = ZMUser.selfUserInContext(managedObjectContext).selfClient()
        assert(self == selfClient)
        
        if let session = try? keysStore.box.sessionWithId(client.remoteIdentifier, fromStringPreKey: preKey) {
            client.fingerprint = session.remoteFingerprint()
            return true
        } else {
            zmLog.error("Cannot create session for prekey \(preKey)")
        }
        
        return false
    }
    
    private func fetchFingerprint() -> NSData? {
        
        return (try? keysStore.box.sessionById(self.remoteIdentifier))?.remoteFingerprint()
    }
    
    /// Use this method only for the selfClient
    public func decrementNumberOfRemainingKeys() {
        let oldValue = numberOfKeysRemaining
        if(numberOfKeysRemaining > 0) {
            numberOfKeysRemaining -= 1
        }
        if(numberOfKeysRemaining < 0) { // this will recover from the fact that the number might already be < 0
                                        // from a previous run
            numberOfKeysRemaining = 0;
        }
        if(oldValue != 0) {
            self.setLocallyModifiedKeys(Set(arrayLiteral: ZMUserClientNumberOfKeysRemainingKey))
        }
    }
}


enum SecurityChangeType {
    case ClientTrusted // a client was trusted by the user on this device
    case ClientDiscovered // a client was discovered, either by receiving a missing response, a message, or fetching all clients
    case ClientIgnored // a client was ignored by the user on this device
    
    func changeSecurityLevel(conversation: ZMConversation, clients: Set<UserClient>, causedBy: ZMOTRMessage?) {
        switch (self) {
        case .ClientTrusted:
            conversation.increaseSecurityLevelIfNeededAfterUserClientsWereTrusted(clients)
            break
        case .ClientIgnored:
            conversation.decreaseSecurityLevelIfNeededAfterUserClientsWereIgnored(clients)
            break
        case .ClientDiscovered:
            conversation.decreaseSecurityLevelIfNeededAfterUserClientsWereDiscovered(clients, causedBy: causedBy)
        }
    }
}


// MARK: Trusting
extension UserClient {
    
    public func trustClient(client: UserClient) {
        trustClients(Set(arrayLiteral: client))
    }
    
    /// Will change conversations security level as side effect
    public func trustClients(clients: Set<UserClient>) {
        guard clients.count > 0 else { return }
        self.mutableSetValueForKey(ZMUserClientIgnoredKey).minusSet(clients)
        self.mutableSetValueForKey(ZMUserClientTrustedKey).unionSet(clients)
        
        clients.forEach { client in client.needsToNotifyUser = false; }
        
        self.changeSecurityLevel(.ClientTrusted, clients: clients, causedBy: nil)
    }

    /// Adds a new client that was just discovered to the ignored ones
    public func addNewClientToIgnored(client: UserClient, causedBy: ZMOTRMessage? = .None) {
        addNewClientsToIgnored(Set(arrayLiteral: client), causedBy: causedBy)
    }
    
    /// Ignore a know client
    public func ignoreClient(client: UserClient) {
        ignoreClients(Set(arrayLiteral: client))
    }
    
    /// Adds to ignored clients, remove from trusted clients, returns the set with the self client excluded
    private func addIgnoredClients(clients: Set<UserClient>) -> Set<UserClient> {
        let notSelfClients = Set(clients.filter {$0 != self})

        guard notSelfClients.count > 0 else { return notSelfClients }
        
        self.mutableSetValueForKey(ZMUserClientTrustedKey).minusSet(notSelfClients)
        self.mutableSetValueForKey(ZMUserClientIgnoredKey).unionSet(notSelfClients)
        
        return notSelfClients
    }

    /// Ignore known clients
    public func ignoreClients(clients: Set<UserClient>) {
        let notSelfClients = self.addIgnoredClients(clients)
        guard notSelfClients.count > 0 else { return}
        self.changeSecurityLevel(.ClientIgnored, clients: notSelfClients, causedBy: .None)
    }

    /// Add new clients that were jsut discovered to the ignored ones
    public func addNewClientsToIgnored(clients: Set<UserClient>, causedBy: ZMOTRMessage? = .None) {
        let notSelfClients = self.addIgnoredClients(clients)
        guard notSelfClients.count > 0 else { return}
        self.changeSecurityLevel(.ClientDiscovered, clients: notSelfClients, causedBy: causedBy)
    }
    
    func activeConversationsForUserOfClients(clients: Set<UserClient>) -> Set<ZMConversation>
    {
        let conversations : Set<ZMConversation> = clients.map{$0.user}.reduce(Set()){
            guard let user = $1 else {return Set()}
            if user.isSelfUser {
                let fetchRequest = NSFetchRequest(entityName: "Conversation")
                fetchRequest.predicate = ZMConversation.predicateForConversationsIncludingArchived()
                let result = user.managedObjectContext?.executeFetchRequestOrAssert(fetchRequest) as? [ZMConversation]!
                if let conversations = result {
                    return $0.union(conversations)
                }
                return Set()
            } else {
                return $0.union(user.activeConversations.array as! [ZMConversation])
            }
        }
        return conversations
    }
    
    func changeSecurityLevel(securityChangeType: SecurityChangeType, clients: Set<UserClient>, causedBy: ZMOTRMessage?) {
        let conversations = activeConversationsForUserOfClients(clients)
        conversations.forEach { conversation in
            if !conversation.isReadOnly {
                let clientsInConversation = clients.filter({ (client) -> Bool in
                    guard let user = client.user else { return false }
                    return conversation.allParticipants.containsObject(user)
                })
                securityChangeType.changeSecurityLevel(conversation, clients: Set(clientsInConversation), causedBy: causedBy)
            }
        }
    }
}

// MARK: APSSignaling
extension UserClient {

    public static func resetSignalingKeysInContext(context: NSManagedObjectContext) {
        guard let selfClient = ZMUser.selfUserInContext(context).selfClient()
        else { return }
        
        selfClient.apsDecryptionKey = nil
        selfClient.apsVerificationKey = nil
        selfClient.needsToUploadSignalingKeys = true
        selfClient.setLocallyModifiedKeys(Set(arrayLiteral: ZMUserClientNeedsToUpdateSignalingKeysKey))
        
        context.enqueueDelayedSave()
    }

}



 