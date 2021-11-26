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

import Foundation
import WireUtilities
import WireSystem
import CoreData

@objc
public enum ZMBlockState: Int {
    case none, blocked, blockedMissingLegalholdConsent
}

@objcMembers
public final class ZMUser: ZMManagedObject {
    @NSManaged private(set) var normalizedName: String?
    
    @NSManaged var normalizedEmailAddress: String?

    @NSManaged public var participantRoles: Set<ParticipantRole>
    
    @NSManaged public var connection: ZMConnection?
    
    @NSManaged public var clients: Set<UserClient>
    
    @NSManaged public var managedBy: String?
    
    public var handle: String? {
        get {
            willAccessValue(forKey: ZMUserKeys.handleKey)
            let value = primitiveValue(forKey: ZMUserKeys.handleKey) as? String
            didAccessValue(forKey: ZMUserKeys.handleKey)
            
            return value
        }
        
        set {
            willChangeValue(forKey: ZMUserKeys.handleKey)
            setPrimitiveValue(newValue, forKey: ZMUserKeys.handleKey)
            didChangeValue(forKey: ZMUserKeys.handleKey)
        }
    }
    
    @NSManaged public var addressBookEntry: AddressBookEntry?
    
    @NSManaged public var readReceiptsEnabledChangedRemotely: Bool
    
    var connectionRequestMessage: String?
    
    @NSManaged private var showingUserAdded: Set<ZMSystemMessage>
    @NSManaged private var showingUserRemoved: Set<ZMSystemMessage>
    @NSManaged private var createdTeams: Set<Team>
    
    // ZMEditableUser
    
    public var name: String? {
        get {
            willAccessValue(forKey: ZMUserKeys.nameKey)
            let value = primitiveValue(forKey: ZMUserKeys.nameKey) as? String
            didAccessValue(forKey: ZMUserKeys.nameKey)
            
            return value
        }
        
        set {
            let newName = newValue?.removingExtremeCombiningCharacters
            
            willChangeValue(forKey: ZMUserKeys.nameKey)
            setPrimitiveValue(newName, forKey: ZMUserKeys.nameKey)
            didChangeValue(forKey: ZMUserKeys.nameKey)
            
            guard let normalizingName = newName else {
                self.normalizedName = nil
                return
            }
            
            normalizedName = (normalizingName as NSString).normalized() as String
        }
    }
    
    public var emailAddress: String? {
        get {
            willAccessValue(forKey: ZMUserKeys.emailAddressKey)
            let value = primitiveValue(forKey: ZMUserKeys.emailAddressKey) as? String
            didAccessValue(forKey: ZMUserKeys.emailAddressKey)
            
            return value
        }
        
        set {
            willChangeValue(forKey: ZMUserKeys.emailAddressKey)
            setPrimitiveValue(newValue, forKey: ZMUserKeys.emailAddressKey)
            didChangeValue(forKey: ZMUserKeys.emailAddressKey)
            
            guard let normalizingEmailAddress = newValue else {
                self.normalizedEmailAddress = nil
                return
            }
            
            normalizedEmailAddress = (normalizingEmailAddress as NSString).normalizedEmailaddress() as String
        }
    }
    
    @NSManaged public var phoneNumber: String?
    @NSManaged public var readReceiptsEnabled: Bool
    @NSManaged public var needsPropertiesUpdate: Bool
    
    @NSManaged public var needsRichProfileUpdate: Bool
    
    @NSManaged public var accentColorValue: ZMAccentColor
    
    
}

public extension ZMUserKeys {
    static let sessionObjectIDKey = "ZMSessionManagedObjectID"
    @objc static let ZMPersistedClientIdKey = "PersistedClientId"
    
    static let accentKey = "accentColorValue"
    static let selfUserObjectIDAsStringKey = "SelfUserObjectID"
    static let selfUserObjectIDKey = "ZMSelfUserManagedObjectID"
    
    static let sessionObjectIDAsStringKey = "SessionObjectID"
    static let selfUserKey = "ZMSelfUser"
    static let normalizedNameKey = "normalizedName"
    static let normalizedEmailAddressKey = "normalizedEmailAddress"
    static let remoteIdentifierKey = "remoteIdentifier"
    
    static let conversationsCreatedKey = "conversationsCreated"
    static let activeCallConversationsKey = "activeCallConversations"
    static let connectionKey = "connection"
    static let emailAddressKey = "emailAddress"
    static let phoneNumberKey = "phoneNumber"
    static let nameKey = "name"
    static let handleKey = "handle"
    static let systemMessagesKey = "systemMessages"
    static let isAccountDeletedKey = "isAccountDeleted"
    static let showingUserAddedKey = "showingUserAdded"
    static let showingUserRemovedKey = "showingUserRemoved"
    static let userClientsKey = "clients"
    static let reactionsKey = "reactions"
    static let addressBookEntryKey = "addressBookEntry"
    static let membershipKey = "membership"
    static let createdTeamsKey = "createdTeams"
    static let serviceIdentifierKey = "serviceIdentifier"
    static let providerIdentifierKey = "providerIdentifier"
    static let availabilityKey = "availability"
    static let expiresAtKey = "expiresAt"
    static let usesCompanyLoginKey = "usesCompanyLogin"
    static let createdTeamMembersKey = "createdTeamMembers"
    static let readReceiptsEnabledKey = "readReceiptsEnabled"
    static let needsPropertiesUpdateKey = "needsPropertiesUpdate"
    static let readReceiptsEnabledChangedRemotelyKey = "readReceiptsEnabledChangedRemotely"
    
    static let teamIdentifierDataKey = "teamIdentifier_data"
    static let teamIdentifierKey = "teamIdentifier"
    
    static let managedByKey = "managedBy"
    static let extendedMetadataKey = "extendedMetadata"
    
    static let richProfileKey = "richProfile"
    static let needsRichProfileUpdateKey = "needsRichProfileUpdate"
    
    static let legalHoldRequestKey = "legalHoldRequest"
    static let needsToAcknowledgeLegalHoldStatusKey = "needsToAcknowledgeLegalHoldStatus"
    
    static let needsToRefetchLabelsKey = "needsToRefetchLabels"
    static let participantRolesKey = "participantRoles"
    
    static let analyticsIdentifierKey = "analyticsIdentifier"
    
    static let lastServerSyncedActiveConversations = "lastServerSyncedActiveConversations"
    
    static let domainKey = "domain"
}

extension ZMUser {
    @objc
    public static override func entityName() -> String {
        return "User"
    }
    
    public override class func sortKey() -> String? {
        ZMUserKeys.normalizedNameKey
    }
    
    public var isServiceUser: Bool {
        serviceIdentifier != nil && providerIdentifier != nil
    }
    
    static var keyPathsForValuesAffectingIsServiceUser: Set<String> {
        Set([ZMUserKeys.serviceIdentifierKey, ZMUserKeys.providerIdentifierKey])
    }
    
    public var isSelfUser: Bool {
        guard
            !isZombieObject,
            let context = managedObjectContext
        else {
            return false
        }
        
        let aa = ZMUser.selfUser(in: context)
        
        return self == aa
    }
    
    @objc
    public func selfClient() -> UserClient? {
        guard
            let id = managedObjectContext?.persistentStoreMetadata(forKey: ZMUserKeys.ZMPersistedClientIdKey),
            let persistedClientID = id as? String
        else {
            return nil
        }
        
        return clients.first { $0.remoteIdentifier == persistedClientID }
    }
    
    @objc
    public var imageMediumData: Data? {
        imageData(for: .complete)
    }
    
    @objc
    public var imageSmallProfileData: Data? {
        imageData(for: .preview)
    }
    
    var keyPathsForValuesAffectingIsConnected: Set<String> {
        Set([ZMUserKeys.connectionKey, "connection.status"])
    }
    
    var keyPathsForValuesAffectingConnectionRequestMessage: Set<String> {
        Set(["connection.message"])
    }
    
    @objc
    public var clientsRequiringUserAttention: Set<UserClient> {
        guard let context = managedObjectContext else { return Set() }
        
        var result = Set<UserClient>()
        
        let selfUser = ZMUser.selfUser(in: context)
        
        clients.forEach {
            if $0.needsToNotifyUser,
               !(selfUser.selfClient()?.trustedClients.contains($0) ?? false) {
                result.insert($0)
            }
        }
        
        return result
    }
    
    
    public var managedByWire: Bool {
        managedBy == nil || managedBy == "wire"
    }
    
    public var isTeamMember: Bool {
        membership != nil
    }
    
    public var isConnected: Bool {
        connection?.status == .accepted
    }
    
    public var canBeConnected: Bool {
        if isServiceUser || isWirelessUser {
            return false
        }
        
        return !isConnected && !isPendingApprovalByOtherUser
    }
    
    public var oneToOneConversation: ZMConversation? {
        guard let context = managedObjectContext else { return nil }
        if isSelfUser {
            return ZMConversation.selfConversation(in: context)
            
        } else if isTeamMember {
            return ZMConversation.fetchOrCreateOneToOneTeamConversation(moc: context,
                                                                        participant: self,
                                                                        team: team,
                                                                        participantRole: nil)
            
        } else {
            return connection?.conversation
            
        }
    }
    
    public var mediumProfileImageCacheKey: String? {
        imageCacheKey(for: .complete)
    }
    
    public var smallProfileImageCacheKey: String? {
        imageCacheKey(for: .preview)
    }
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        needsToBeUpdatedFromBackend = true
    }
    
    public func refreshData() {
        needsToBeUpdatedFromBackend = true
    }
    
}

// MARK: - Internal

extension ZMUser {
    public override func keysTrackedForLocalModifications() -> Set<String> {
        return isSelfUser ? super.keysTrackedForLocalModifications() : Set()
    }
    
    public override var ignoredKeys: Set<AnyHashable>? {
        return (super.ignoredKeys ?? Set())
            .union([
                ZMUserKeys.analyticsIdentifierKey,
                ZMUserKeys.normalizedNameKey,
                ZMUserKeys.conversationsCreatedKey,
                ZMUserKeys.activeCallConversationsKey,
                ZMUserKeys.connectionKey,
                ZMUserKeys.conversationsCreatedKey,
                ZMUserKeys.participantRolesKey,
                ZMUserKeys.normalizedEmailAddressKey,
                ZMUserKeys.systemMessagesKey,
                ZMUserKeys.userClientsKey,
                ZMUserKeys.showingUserAddedKey,
                ZMUserKeys.showingUserRemovedKey,
                ZMUserKeys.reactionsKey,
                ZMUserKeys.addressBookEntryKey,
                ZMUserKeys.handleKey,
                ZMUserKeys.membershipKey,
                ZMUserKeys.createdTeamsKey,
                ZMUserKeys.serviceIdentifierKey,
                ZMUserKeys.providerIdentifierKey,
                ZMUserKeys.expiresAtKey,
                ZMUserKeys.teamIdentifierDataKey,
                ZMUserKeys.usesCompanyLoginKey,
                ZMUserKeys.needsPropertiesUpdateKey,
                ZMUserKeys.readReceiptsEnabledChangedRemotelyKey,
                ZMUserKeys.isAccountDeletedKey,
                ZMUserKeys.managedByKey,
                ZMUserKeys.richProfileKey,
                ZMUserKeys.needsRichProfileUpdateKey,
                ZMUserKeys.createdTeamMembersKey,
                ZMUserKeys.legalHoldRequestKey,
                ZMUserKeys.needsToAcknowledgeLegalHoldStatusKey,
                ZMUserKeys.needsToRefetchLabelsKey,
                ZMUserKeys.lastServerSyncedActiveConversations, // OBSOLETE
                ZMUserKeys.domainKey
            ])
    }
    
    @objc(userWithEmailAddress:inContext:)
    static func userWithEmailAddress(_ emailAddress: String, in context: NSManagedObjectContext) -> ZMUser? {
        require(emailAddress.count > 0, "emailAddress required")
        
        let request = NSFetchRequest<ZMUser>(entityName: entityName())
        request.predicate = NSPredicate(format: "%K = %@", argumentArray: [ZMUserKeys.emailAddressKey, emailAddress])
        let users = context.fetchOrAssert(request: request)
        
        require(users.count <= 1, "More than one user with the same email address")
        
        return users.first
    }
    
    @objc(userWithPhoneNumber:inContext:)
    static func user(with phoneNumber: String, in context: NSManagedObjectContext) -> ZMUser? {
        require(phoneNumber.count > 0, "phoneNumber required")
        
        let request = NSFetchRequest<ZMUser>(entityName: entityName())
        request.predicate = NSPredicate(format: "%K = %@", argumentArray: [ZMUserKeys.phoneNumberKey, phoneNumber])
        let users = context.fetchOrAssert(request: request)
        
        require(users.count <= 1, "More than one user with the same phone number")
        
        return users.first
    }
    
    static func users(with remoteIDs: Set<UUID>, in context: NSManagedObjectContext) -> Set<ZMUser> {
        (fetchObjects(withRemoteIdentifiers: remoteIDs, in: context) as? Set<ZMUser>) ?? Set()
    }
    
    @objc dynamic
    public var remoteIdentifier: UUID! {
        get {
            transientUUID(forKey: #keyPath(ZMUser.remoteIdentifier))
        }
        
        set {
            setTransientUUID(newValue, forKey: #keyPath(ZMUser.remoteIdentifier))
        }
    }
    
    @objc
    public var teamIdentifier: UUID? {
        get {
            transientUUID(forKey: #keyPath(ZMUser.teamIdentifier))
        }
        
        set {
            setTransientUUID(newValue, forKey: #keyPath(ZMUser.teamIdentifier))
        }
    }
    
    static func accentColor(fromPayloadValue value: NSNumber?) -> ZMAccentColor {
        let rawValue = value?.int16Value ?? -1
        
        guard
            rawValue > ZMAccentColor.undefined.rawValue,
            rawValue <= ZMAccentColor.max.rawValue,
            let color = ZMAccentColor(rawValue: rawValue)
        else {
            let randomValue = (Int16)(arc4random_uniform(UInt32(ZMAccentColor.max.rawValue) - 1) + 1)
            return ZMAccentColor(rawValue: randomValue) ?? ZMAccentColor.strongBlue
        }
        
        return color
    }
    
    @objc(updateWithTransportData:authoritative:)
    public func update(withTransportData transportData: Dictionary<AnyHashable, Any>, authoritative: Bool) {
        if let serviceData = transportData["service"] as? Dictionary<AnyHashable, Any> {
            if let serviceIdentifier = serviceData["id"] as? String {
                self.serviceIdentifier = serviceIdentifier
            }
            if let providerIdentifier = serviceData["provider"] as? String {
                self.providerIdentifier = providerIdentifier
            }
        }
        
        if let deleted = transportData["deleted"] as? Bool,
           deleted,
           !isAccountDeleted {
            markAccountAsDeleted(at: Date())
        }
        
        let ssoID = transportData["sso_id"]
        if ssoID != nil || authoritative {
            usesCompanyLogin = ssoID != nil
        }
            
        if let qualifiedID = transportData["qualified_id"] as? Dictionary<AnyHashable, Any> {
            let domain = qualifiedID["domain"] as? String
            if self.domain == nil {
                self.domain = domain
            } else {
                let message = "User domain do not match in update: \(String(describing: domain)) vs. \(String(describing: self.domain))"
                require(self.domain == domain, message)
            }
            
            if let remoteIdentifierString = qualifiedID["id"] as? String,
               let remoteIdentifier = UUID(uuidString: remoteIdentifierString) {
                if self.remoteIdentifier == nil {
                    self.remoteIdentifier = remoteIdentifier
                } else {
                    let message = "User ids do not match in update: \(String(describing: remoteIdentifier)) vs. \(String(describing: self.remoteIdentifier))"
                    require(self.remoteIdentifier == remoteIdentifier, message)
                }
            }
        } else {
            if let remoteIdentifierString = transportData["id"] as? String,
               let remoteIdentifier = UUID(uuidString: remoteIdentifierString) {
                if self.remoteIdentifier == nil {
                    self.remoteIdentifier = remoteIdentifier
                } else {
                    let message = "User ids do not match in update: \(String(describing: remoteIdentifier)) vs. \(String(describing: self.remoteIdentifier))"
                    require(self.remoteIdentifier == remoteIdentifier, message)
                }
            }
        }
        
        let name = transportData["name"] as? String
        if !isAccountDeleted,
           (name != nil || authoritative) {
            self.name = name
        }
        
        let managedBy = transportData["managed_by"] as? String
        if managedBy != nil || authoritative {
            self.managedBy = managedBy
        }
        
        let handle = transportData["handle"] as? String
        if handle != nil || authoritative {
            self.handle = handle
        }
        
        let teamIdentifierString = (transportData["team"] as? String) ?? ""
        let teamIdentifier = UUID(uuidString: teamIdentifierString)
        if teamIdentifier != nil || authoritative {
            self.teamIdentifier = teamIdentifier
            createOrDeleteMembershipIfBelongingToTeam()
        }
        
        let emailAddress = transportData["email"]
        if emailAddress != nil || authoritative {
            self.emailAddress = (emailAddress as? String)?.removingExtremeCombiningCharacters
        }
        
        let phoneNumber = transportData["phone"]
        if phoneNumber != nil || authoritative {
            self.phoneNumber = (phoneNumber as? String)?.removingExtremeCombiningCharacters
        }
        
        let accentID = transportData["accent_id"] as? NSNumber
        if accentID != nil || authoritative {
            self.accentColorValue = ZMUser.accentColor(fromPayloadValue: accentID)
        }
        
        if let expiryDate = (transportData as NSDictionary).optionalDate(forKey: "expires_at") {
            self.expiresAt = expiryDate
        }
        
        if let assets = transportData["assets"] as? NSArray {
            updateAssetData(with: assets, authoritative: authoritative)
        }
        
        if authoritative {
            needsToBeUpdatedFromBackend = false
        }
        
        updatePotentialGapSystemMessagesIfNeeded()
    }
    
    public func updatePotentialGapSystemMessagesIfNeeded() {
        showingUserAdded.forEach {
            $0.updateNeedsUpdatingUsersIfNeeded()
        }
        
        showingUserRemoved.forEach {
            $0.updateNeedsUpdatingUsersIfNeeded()
        }
    }
    
    public override static func predicateForObjectsThatNeedToBeUpdatedUpstream() -> NSPredicate? {
        guard let basePredicate = super.predicateForObjectsThatNeedToBeUpdatedUpstream() else { return nil }
        let needsToBeUpdatedPredicate = NSPredicate(format: "needsToBeUpdatedFromBackend == 0")
        let nilRemoteIdentifierPredicate = NSPredicate(format: "%K == nil && %K == nil",
                                                       argumentArray: [previewProfileAssetIdentifierKey,
                                                                       completeProfileAssetIdentifierKey])
        let notNilRemoteIdentifierPredicate = NSPredicate(format: "%K != nil && %K != nil",
                                                          argumentArray: [previewProfileAssetIdentifierKey,
                                                                          completeProfileAssetIdentifierKey])
        
        let remoteIdentifier = NSCompoundPredicate(orPredicateWithSubpredicates: [nilRemoteIdentifierPredicate, notNilRemoteIdentifierPredicate])
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, needsToBeUpdatedPredicate, remoteIdentifier])
    }
    
    func update(withSearchResult name: String?, handle: String?) {
        if name != nil, name != self.name {
            self.name = name
        }
        
        if handle != nil, handle != self.handle {
            self.handle = handle
        }
    }
}

// MARK: - SelfUser

extension ZMUser {
    static func storedObjectID(for userInfoKey: String,
                               persistedMetadataKey: String,
                               in context: NSManagedObjectContext) -> NSManagedObjectID? {
        if let moID = context.userInfo[userInfoKey] as? NSManagedObjectID {
            return moID
        }
        
        guard
            let moIDString = context.persistentStoreMetadata(forKey: persistedMetadataKey) as? String,
            let moIDURL = URL(string: moIDString),
            let moID = context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: moIDURL)
        else {
            return nil
        }
        
        context.userInfo[userInfoKey] = moID
        
        return moID
    }
    
    static func obtainCachedSession(by id: NSManagedObjectID,
                                    in context: NSManagedObjectContext) -> ZMUser? {
        guard
            let object = try? context.existingObject(with: id),
            let session = object as? ZMSession
        else {
            return nil
        }
        
        return session.selfUser
    }
    
    static func obtainCachedSelfUser(by id: NSManagedObjectID,
                                     in context: NSManagedObjectContext) -> ZMUser? {
        guard
            let object = try? context.existingObject(with: id),
            let user = object as? ZMUser
        else {
            return nil
        }
        
        return user
    }
    
    static func createSessionIfNeeded(in context: NSManagedObjectContext,
                                      with existingSelfUser: ZMUser?) -> ZMUser {
        context.userInfo.removeObject(forKey: ZMUserKeys.selfUserObjectIDKey)
        context.setPersistentStoreMetadata(nil as Data?, key: ZMUserKeys.selfUserObjectIDAsStringKey)
        
        let request = ZMSession.sortedFetchRequest()
        let session: ZMSession
        let selfUser: ZMUser
        
        if let existingSession = context.executeFetchRequestOrAssert(request).first as? ZMSession {
            session = existingSession
            selfUser = existingSelfUser ?? session.selfUser
            
        } else {
            session = ZMSession.insertNewObject(in: context)
            
            do {
                try context.obtainPermanentIDs(for: [session])
            } catch {
                fatal("Failed to get ID for session: \((error as NSError).code)")
            }
            
            if let existingSelfUser = existingSelfUser {
                selfUser = existingSelfUser
                
            } else {
                selfUser = ZMUser.insertNewObject(in: context)
                
                do {
                    try context.obtainPermanentIDs(for: [selfUser])
                } catch {
                    fatal("Failed to get ID for self user: \((error as NSError).code)")
                }
                
            }
            
        }
        
        session.selfUser = selfUser
        
        context.userInfo[ZMUserKeys.sessionObjectIDKey] = session.objectID
        
        let metadata = session.objectID.uriRepresentation().absoluteString
        context.setPersistentStoreMetadata(metadata, key: ZMUserKeys.sessionObjectIDAsStringKey)
        
        let _ = context.makeMetadataPersistent()
        
        do {
            try context.save()
        } catch {
            let message = "Failed to save self user: \((error as NSError).code)"
            require(false, message)
        }
        
        return selfUser
    }
    
    static func unboxSelfUser(from context: NSManagedObjectContext) -> ZMUser? {
        let boxedSelfUser = context.userInfo[ZMUserKeys.selfUserKey] as? ZMBoxedSelfUser
        return boxedSelfUser?.selfUser
    }
    
    public static func boxSelfUser(_ selfUser: ZMUser, inContextUserInfo context: NSManagedObjectContext) {
        let boxed = ZMBoxedSelfUser()
        boxed.selfUser = selfUser
        context.userInfo[ZMUserKeys.selfUserKey] = boxed
    }
    
    static func hasSessionEntity(in context: NSManagedObjectContext) -> Bool {
        context.persistentStoreCoordinator?.managedObjectModel.entitiesByName[ZMSession.entityName()] != nil
    }
    
    @objc(selfUserInContext:)
    public static func selfUser(in context: NSManagedObjectContext) -> ZMUser {
        if let existingSelfUser = unboxSelfUser(from: context) {
            return existingSelfUser
        }
        
        var selfUser: ZMUser
        if let sessionID = storedObjectID(for: ZMUserKeys.sessionObjectIDKey,
                                          persistedMetadataKey: ZMUserKeys.sessionObjectIDAsStringKey,
                                          in: context),
           let existingSelfUser = obtainCachedSession(by: sessionID, in: context) {
            selfUser = existingSelfUser
            
        } else if let selfUserID = storedObjectID(for: ZMUserKeys.selfUserObjectIDKey,
                                                  persistedMetadataKey: ZMUserKeys.selfUserObjectIDAsStringKey,
                                                  in: context),
                  let existingSelfUser = obtainCachedSession(by: selfUserID, in: context) {
            selfUser = createSessionIfNeeded(in: context, with: existingSelfUser)
            
        } else {
            selfUser = createSessionIfNeeded(in: context, with: nil)
            
        }
        
        boxSelfUser(selfUser, inContextUserInfo: context)
        
        return selfUser
    }
}

// MARK: - Utilities

extension ZMUser {
    public static func selfUser(inUserSession session: ContextProvider?) -> (ZMUser & ZMEditableUser) {
        guard let session = session else {
            fatal("session should not be nil")
        }
        return selfUser(in: session.viewContext)
    }
}

// MARK: - ImageData

extension ZMUser {
    
    public static func predicateForUsersOtherThanSelf() -> NSPredicate {
        return NSPredicate(format: "isSelfUser != YES")
    }
    
    public static func predicateForSelfUser() -> NSPredicate {
        return NSPredicate(format: "isSelfUser = YES")
    }
    
}

// MARK: - Connections

extension ZMUser {
    
    static var keyPathsForValuesAffectingIsBlocked: Set<String> {
        Set([ZMUserKeys.connectionKey, "connection.status"])
    }
    
    static var keyPathsForValuesAffectingBlockStateReason: Set<String> {
        Set([ZMUserKeys.connectionKey, "connection.status"])
    }
    
    static var keyPathsForValuesAffectingIsIgnored: Set<String> {
        Set([ZMUserKeys.connectionKey, "connection.status"])
    }
    
    static var keyPathsForValuesAffectingIsPendingApprovalBySelfUser: Set<String> {
        Set([ZMUserKeys.connectionKey, "connection.status"])
    }
    
    static var keyPathsForValuesAffectingIsPendingApprovalByOtherUser: Set<String> {
        Set([ZMUserKeys.connectionKey, "connection.status"])
    }
    
    public var isBlocked: Bool {
        blockState != .none
    }
    
    public var isIgnored: Bool {
        connection?.status == .ignored
    }
    
    public var isPendingApprovalBySelfUser: Bool {
        connection?.status == .pending
    }
    
    public var isPendingApprovalByOtherUser: Bool {
        connection?.status == .sent
    }
    
    public var blockState: ZMBlockState {
        guard let connection = connection else { return .none }
        
        switch connection.status {
        case .blocked:
            return .blocked
            
        case .blockedMissingLegalholdConsent:
            return .blockedMissingLegalholdConsent
            
        default:
            return .none
        }
    }
    
}

extension ZMUser: UserType {
    
    @objc
    public var hasTeam: Bool {
        /// Other users won't have a team object, but a teamIdentifier.
        return nil != team || nil != teamIdentifier
    }

    /// Whether all user's devices are verified by the selfUser
    public var isTrusted: Bool {
        let selfUser = managedObjectContext.map(ZMUser.selfUser)
        let selfClient = selfUser?.selfClient()
        let hasUntrustedClients = self.clients.contains(where: { ($0 != selfClient) && !(selfClient?.trustedClients.contains($0) ?? false) })
        
        return !hasUntrustedClients
    }
    
    public func isGuest(in conversation: ConversationLike) -> Bool {
        return _isGuest(in: conversation)
    }
    
    public var teamName: String? {
        return team?.name
    }
    
    public var hasDigitalSignatureEnabled: Bool {
        return team?.fetchFeatureFlag(with: .digitalSignature)?.isEnabled ?? false
    }
    
    public var previewImageData: Data? {
        return imageSmallProfileData
    }
    
    public var completeImageData: Data? {
        return imageMediumData
    }
    
    public var activeConversations: Set<ZMConversation> {
        return Set(self.participantRoles.compactMap {$0.conversation})
    }
    
    public var isVerified: Bool {
        guard let selfUser = managedObjectContext.map(ZMUser.selfUser) else {
            return false
        }
        return isTrusted && selfUser.isTrusted && !clients.isEmpty
    }

    public var isFederated: Bool {
        guard let selfUser = managedObjectContext.map(ZMUser.selfUser) else {
            return false
        }

        return selfUser.isFederating(with: self)
    }

    // MARK: - Conversation Roles

    public func canManagedGroupRole(of user: UserType, conversation: ZMConversation) -> Bool {
        guard isGroupAdmin(in: conversation) else { return false }
        return !user.isSelfUser && (user.isConnected || isOnSameTeam(otherUser: user))
    }

    public func isGroupAdmin(in conversation: ConversationLike) -> Bool {
        return role(in: conversation)?.name == ZMConversation.defaultAdminRoleName
    }

    public func role(in conversation: ConversationLike?) -> Role? {
        return participantRoles.first(where: { $0.conversation === conversation })?.role
    }

    // MARK: Legal Hold

    @objc public var isUnderLegalHold: Bool {
        return clients.any(\.isLegalHoldDevice)
    }

    @objc class func keyPathsForValuesAffectingIsUnderLegalHold() -> Set<String> {
        return [UserClientsKey, "clients.deviceClass"]
    }
    
    public var allClients: [UserClientType] {
        return Array(clients)
    }

    // MARK: - Data refresh requests

    public func refreshRichProfile() {
        needsRichProfileUpdate = true
    }

    public func refreshMembership() {
        membership?.needsToBeUpdatedFromBackend = true
    }

    public func refreshTeamData() {
        team?.refreshMetadata()
    }
    
}

public struct AssetKey {
    
    static let legalCharacterSet = CharacterSet.alphanumerics.union(CharacterSet.punctuationCharacters)
    
    public init?(_ string: String) {
        if AssetKey.validate(string: string) {
            stringValue = string
        } else {
            return nil
        }
    }
    
    let stringValue : String
    
    fileprivate static func validate(string : String) -> Bool {
        return CharacterSet(charactersIn: string).isSubset(of: legalCharacterSet)
    }
}

@objc public enum ProfileImageSize: Int {
    case preview
    case complete
    
    public var imageFormat: ZMImageFormat {
        switch self {
        case .preview:
            return .profile
        case .complete:
            return .medium
        }
    }

    public init?(stringValue: String) {
        switch stringValue {
        case ProfileImageSize.preview.stringValue: self = .preview
        case ProfileImageSize.complete.stringValue: self = .complete
        default: return nil
        }
    }

    var stringValue: String {
        switch self {
        case .preview: return "preview"
        case .complete: return "complete"
        }
    }
    
    public static var allSizes: [ProfileImageSize] {
        return [.preview, .complete]
    }
}

extension ProfileImageSize: CustomDebugStringConvertible {
     public var debugDescription: String {
        switch self {
        case .preview:
            return "ProfileImageSize.preview"
        case .complete:
            return "ProfileImageSize.complete"
        }
    }
}

extension ZMUser: ServiceUser {
    @NSManaged public var providerIdentifier: String?
    @NSManaged public var serviceIdentifier: String?
}

public extension Notification.Name {
    static let userDidRequestPreviewAsset = Notification.Name("UserDidRequestPreviewAsset")
    static let userDidRequestCompleteAsset = Notification.Name("UserDidRequestCompleteAsset")
}

extension ZMUser {
    
    @objc static public let previewProfileAssetIdentifierKey = #keyPath(ZMUser.previewProfileAssetIdentifier)
    @objc static public let completeProfileAssetIdentifierKey = #keyPath(ZMUser.completeProfileAssetIdentifier)

    @NSManaged public var previewProfileAssetIdentifier: String?
    @NSManaged public var completeProfileAssetIdentifier: String?
    
    /// Conversations created by this user
    @NSManaged var conversationsCreated: Set<ZMConversation>
    
    /// Team membership for this user
    @NSManaged public internal(set) var membership: Member?

    /// Reactions expressed by this user
    @NSManaged var reactions: Set<Reaction>
    
    /// System messages referencing this user
    @NSManaged var systemMessages: Set<ZMSystemMessage>
    
    @NSManaged public var expiresAt: Date?
    
    /// `accountIsDeleted` is true if this account has been deleted on the backend
    @NSManaged public internal(set) var isAccountDeleted: Bool
    
    @NSManaged public var usesCompanyLogin: Bool
    
    /// If `needsToRefetchLabels` is true we need to refetch the conversation labels (favorites & folders)
    @NSManaged public var needsToRefetchLabels: Bool
    
    @NSManaged public var domain: String?
    
    @objc(setImageData:size:)
    public func setImage(data: Data?, size: ProfileImageSize) {
        guard let imageData = data else {
            managedObjectContext?.zm_userImageCache?.removeAllUserImages(self)
            return
        }
        managedObjectContext?.zm_userImageCache?.setUserImage(self, imageData: imageData, size: size)
        
        if let uiContext = managedObjectContext?.zm_userInterface {
            let changedKey = size == .preview ? #keyPath(ZMUser.previewImageData) : #keyPath(ZMUser.completeImageData)
            NotificationDispatcher.notifyNonCoreDataChanges(objectID: objectID, changedKeys: [changedKey], uiContext: uiContext)
        }
    }
    
    public func imageData(for size: ProfileImageSize, queue: DispatchQueue, completion: @escaping (_ imageData: Data?) -> Void) {
        managedObjectContext?.zm_userImageCache?.userImage(self, size: size, queue: queue, completion: completion)
    }
    
    @objc(imageDataforSize:)
    public func imageData(for size: ProfileImageSize) -> Data? {
        return managedObjectContext?.zm_userImageCache?.userImage(self, size: size)
    }
    
    public static var previewImageDownloadFilter: NSPredicate {
        let assetIdExists = NSPredicate(format: "(%K != nil)", ZMUser.previewProfileAssetIdentifierKey)
        let assetIdIsValid = NSPredicate { (user, _) -> Bool in
            guard let user = user as? ZMUser else { return false }
            return user.previewProfileAssetIdentifier?.isValidAssetID ?? false
        }
        let notCached = NSPredicate() { (user, _) -> Bool in
            guard let user = user as? ZMUser else { return false }
            return user.imageSmallProfileData == nil
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: [assetIdExists, assetIdIsValid, notCached])
    }

    public static var completeImageDownloadFilter: NSPredicate {
        let assetIdExists = NSPredicate(format: "(%K != nil)", ZMUser.completeProfileAssetIdentifierKey)
        let assetIdIsValid = NSPredicate { (user, _) -> Bool in
            guard let user = user as? ZMUser else { return false }
            return user.completeProfileAssetIdentifier?.isValidAssetID ?? false
        }
        let notCached = NSPredicate() { (user, _) -> Bool in
            guard let user = user as? ZMUser else { return false }
            return user.imageMediumData == nil
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: [assetIdExists, assetIdIsValid, notCached])
    }
    
    public func updateAndSyncProfileAssetIdentifiers(previewIdentifier: String, completeIdentifier: String) {
        guard isSelfUser else { return }
        previewProfileAssetIdentifier = previewIdentifier
        completeProfileAssetIdentifier = completeIdentifier
        setLocallyModifiedKeys([ZMUser.previewProfileAssetIdentifierKey, ZMUser.completeProfileAssetIdentifierKey])
    }
    
    @objc public func updateAssetData(with assets: NSArray?, authoritative: Bool) {
        guard !hasLocalModifications(forKeys: [ZMUser.previewProfileAssetIdentifierKey, ZMUser.completeProfileAssetIdentifierKey]) else { return }
        guard let assets = assets as? [[String : String]], !assets.isEmpty else {
            if authoritative {
                previewProfileAssetIdentifier = nil
                completeProfileAssetIdentifier = nil
            }
            return
        }
        for data in assets {
            if let size = data["size"].flatMap(ProfileImageSize.init), let key = data["key"].flatMap(AssetKey.init) {
                switch size {
                case .preview:
                    if key.stringValue != previewProfileAssetIdentifier {
                        previewProfileAssetIdentifier = key.stringValue
                    }
                case .complete:
                    if key.stringValue != completeProfileAssetIdentifier {
                        completeProfileAssetIdentifier = key.stringValue
                    }
                }
            }
        }
    }
    
    @objc public func requestPreviewProfileImage() {
        guard let moc = self.managedObjectContext, moc.zm_isUserInterfaceContext, !moc.zm_userImageCache.hasUserImage(self, size: .preview) else { return }
        
        NotificationInContext(name: .userDidRequestPreviewAsset,
                              context: moc.notificationContext,
                              object: self.objectID).post()
    }
    
    @objc public func requestCompleteProfileImage() {
        guard let moc = self.managedObjectContext, moc.zm_isUserInterfaceContext, !moc.zm_userImageCache.hasUserImage(self, size: .complete) else { return }
        
        NotificationInContext(name: .userDidRequestCompleteAsset,
                              context: moc.notificationContext,
                              object: self.objectID).post()
    }
    
    /// Mark the user's account as having been deleted. This will also remove the user from any conversations he/she
    /// is still a participant of.
    @objc public func markAccountAsDeleted(at timestamp: Date) {
        isAccountDeleted = true
        removeFromAllConversations(at: timestamp)
    }
    
    /// Remove user from all group conversations he is a participant of
    fileprivate func removeFromAllConversations(at timestamp: Date) {
        let allGroupConversations: [ZMConversation] = participantRoles.compactMap {
            guard let convo = $0.conversation,
                convo.conversationType == .group else { return nil}
            return convo
        }
        
        allGroupConversations.forEach { conversation in
            if isTeamMember && conversation.team == team {
                conversation.appendTeamMemberRemovedSystemMessage(user: self, at: timestamp)
            } else {
                conversation.appendParticipantRemovedSystemMessage(user: self, at: timestamp)
            }
            conversation.removeParticipantAndUpdateConversationState(user: self, initiatingUser: self)
        }
    }
}

extension ZMUser {
    // MARK: - Participant role
    
    @objc
    public var conversations: Set<ZMConversation> {
        return Set(participantRoles.compactMap{ return $0.conversation })
    }
}

extension NSManagedObject: SafeForLoggingStringConvertible {
    public var safeForLoggingDescription: String {
        let moc: String = self.managedObjectContext?.description ?? "nil"
        
        return "\(type(of: self)) \(Unmanaged.passUnretained(self).toOpaque()): moc=\(moc) objectID=\(self.objectID)"
    }
}

extension ZMUser {
    
    /// The initials e.g. "JS" for "John Smith"
    @objc public var initials: String? {
        return PersonName.person(withName: self.name ?? "", schemeTagger: nil).initials
    }
}

extension ZMUser: UserConnections {

    public func connect(completion: @escaping (Error?) -> Void) {
        ZMUser.selfUser(in: managedObjectContext!).sendConnectionRequest(to: self) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }

    public func accept(completion: @escaping (Error?) -> Void) {
        connection?.updateStatus(.accepted, completion: { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        })
    }

    public func ignore(completion: @escaping (Error?) -> Void) {
        connection?.updateStatus(.ignored, completion: { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        })
    }

    public func block(completion: @escaping (Error?) -> Void) {
        connection?.updateStatus(.blocked, completion: { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        })
    }

    public func cancelConnectionRequest(completion: @escaping (Error?) -> Void) {
        connection?.updateStatus(.cancelled, completion: { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        })
    }
    
}

@objc
extension NSUUID {
    func isSelfUserRemoteIdentifierInContext(_ context: NSManagedObjectContext) -> Bool {
        ZMUser.selfUser(in: context).remoteIdentifier!.uuidString == self.uuidString
    }
}
