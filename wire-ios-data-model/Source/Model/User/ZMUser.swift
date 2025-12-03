//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireFoundation
import WireSystem
import WireTransport
import WireUtilities

extension ZMUser: UserType {

    @NSManaged private var typeValue: Int16

    private var typeKey: String { "typeValue" }

    /// Whether the user is a regular user, an app or a bot.

    public var type: TypeOfUser {
        get {
            willAccessValue(forKey: typeKey)
            let rawValue = primitiveValue(forKey: typeKey) as? Int16 ?? 0
            didAccessValue(forKey: typeKey)
            return TypeOfUser(rawValue: rawValue) ?? .regular
        }
        set {
            willChangeValue(forKey: typeKey)
            setPrimitiveValue(newValue.rawValue, forKey: typeKey)
            didChangeValue(forKey: typeKey)
        }
    }

    @objc public var hasTeam: Bool {
        // Other users won't have a team object, but a teamIdentifier.
        team != nil || teamIdentifier != nil
    }

    /// Whether all user's devices are verified by the selfUser
    public var isTrusted: Bool {
        let selfUser = managedObjectContext.map(ZMUser.selfUser)
        let selfClient = selfUser?.selfClient()
        let hasUntrustedClients = clients
            .contains(where: { ($0 != selfClient) && !(selfClient?.trustedClients.contains($0) ?? false) })

        return !hasUntrustedClients
    }

    public func isGuest(in conversation: ConversationLike) -> Bool {
        _isGuest(in: conversation)
    }

    @objc public var isApp_: Bool { // TODO: remove underscore
        type == .app
    }

    @objc public var isBot: Bool {
        type == .bot
    }

    @objc public var isAppOrBot: Bool {
        isApp_ || isBot
    }

    public var teamName: String? {
        team?.name
    }

    public var hasDigitalSignatureEnabled: Bool {
        guard let context = managedObjectContext else { return false }
        let featureRepository = LegacyFeatureRepository(context: context)
        return featureRepository.fetchDigitalSignature().status == .enabled
    }

    private func isMLSEnabled() -> Bool {
        guard let context = managedObjectContext else { return false }
        let mlsFeature = LegacyFeatureRepository(context: context).fetchMLS()
        return mlsFeature.isEnabled
    }

    public var accentColor: AccentColor? {
        get { .init(rawValue: accentColorValue) }
        set { accentColorValue = newValue?.rawValue ?? AccentColor.default.rawValue }
    }

    public var zmAccentColor: ZMAccentColor? {
        get { .from(rawValue: accentColorValue) }
        set { accentColorValue = newValue?.rawValue ?? AccentColor.default.rawValue }
    }

    public var previewImageData: Data? {
        imageSmallProfileData
    }

    public var completeImageData: Data? {
        imageMediumData
    }

    public var activeConversations: Set<ZMConversation> {
        Set(participantRoles.compactMap(\.conversation))
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

    // MARK: - One on one conversation

    /// The one on one conversation with this user.

    @NSManaged public var oneOnOneConversation: ZMConversation?

    // MARK: - Conversation Roles

    public func canManagedGroupRole(of user: UserType, conversation: ZMConversation) -> Bool {
        guard isGroupAdmin(in: conversation) else { return false }
        return !user.isSelfUser && (user.isConnected || isOnSameTeam(otherUser: user))
    }

    public func isGroupAdmin(in conversation: ConversationLike) -> Bool {
        role(in: conversation)?.name == ZMConversation.defaultAdminRoleName
    }

    public func role(in conversation: ConversationLike) -> Role? {
        participantRole(in: conversation)?.role
    }

    public func participantRole(in conversation: ConversationLike) -> ParticipantRole? {
        participantRoles.first { $0.conversation === conversation }
    }

    // MARK: Legal Hold

    @objc public var isUnderLegalHold: Bool {
        clients.any(\.isLegalHoldDevice)
    }

    @objc
    class func keyPathsForValuesAffectingIsUnderLegalHold() -> Set<String> {
        [UserClientsKey, "clients.deviceClass"]
    }

    public var allClients: [UserClientType] {
        Array(clients)
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

    // MARK: - MLS

    public var canCreateMLSGroups: Bool {
        guard
            let id = remoteIdentifier,
            let context = managedObjectContext
        else {
            return false
        }

        let mlsFeature = LegacyFeatureRepository(context: context).fetchMLS()
        return mlsFeature.isEnabled && mlsFeature.config.protocolToggleUsers.contains(id)
    }

}

public struct AssetKey {

    static let legalCharacterSet = CharacterSet.alphanumerics.union(CharacterSet.punctuationCharacters)

    public init?(_ string: String) {
        if AssetKey.validate(string: string) {
            self.stringValue = string
        } else {
            return nil
        }
    }

    let stringValue: String

    fileprivate static func validate(string: String) -> Bool {
        CharacterSet(charactersIn: string).isSubset(of: legalCharacterSet)
    }
}

@objc
public enum ProfileImageSize: Int {
    case preview
    case complete

    public var imageFormat: ZMImageFormat {
        switch self {
        case .preview:
            .profile
        case .complete:
            .medium
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
        case .preview: "preview"
        case .complete: "complete"
        }
    }

    public static var allSizes: [ProfileImageSize] {
        [.preview, .complete]
    }
}

extension ProfileImageSize: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .preview:
            "ProfileImageSize.preview"
        case .complete:
            "ProfileImageSize.complete"
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

public extension ZMUser {

    @objc static let previewProfileAssetIdentifierKey = #keyPath(ZMUser.previewProfileAssetIdentifier)
    @objc static let completeProfileAssetIdentifierKey = #keyPath(ZMUser.completeProfileAssetIdentifier)

    @NSManaged var previewProfileAssetIdentifier: String?
    @NSManaged var completeProfileAssetIdentifier: String?

    /// Conversations created by this user
    @NSManaged internal var conversationsCreated: Set<ZMConversation>

    /// Team membership for this user
    @NSManaged internal(set) var membership: Member?

    /// Reactions expressed by this user
    @NSManaged internal var reactions: Set<Reaction>

    /// System messages referencing this user
    @NSManaged internal var systemMessages: Set<ZMSystemMessage>

    @NSManaged var expiresAt: Date?

    /// `accountIsDeleted` is true if this account has been deleted on the backend
    @NSManaged var isAccountDeleted: Bool

    @NSManaged var usesCompanyLogin: Bool

    /// If `needsToRefetchLabels` is true we need to refetch the conversation labels (favorites & folders)
    @NSManaged var needsToRefetchLabels: Bool

    /// The analytics identifier used for tag analytic events.
    ///
    /// This identifier should only exist for the self user

    @objc var trackingID: UUID? {
        get { analyticsIdentifier.flatMap(UUID.init(transportString:)) }
        set { analyticsIdentifier = newValue?.transportString() }
    }

    @NSManaged var analyticsIdentifier: String?

    internal static let domainKey: String = "domain"
    @NSManaged private var primitiveDomain: String?
    var domain: String? {
        get {
            willAccessValue(forKey: Self.domainKey)
            let value = primitiveDomain
            didAccessValue(forKey: Self.domainKey)
            return value
        }

        set {
            willChangeValue(forKey: Self.domainKey)
            primitiveDomain = newValue
            didChangeValue(forKey: Self.domainKey)
            updatePrimaryKey(remoteIdentifier: remoteIdentifier, domain: newValue)
        }
    }

    internal static let remoteIdentifierKey: String = "remoteIdentifier"
    @NSManaged private var primitiveRemoteIdentifier: String?
    // keep the same as objc non_specified for now
    var remoteIdentifier: UUID! {
        get {
            willAccessValue(forKey: Self.remoteIdentifierKey)
            let value = transientUUID(forKey: Self.remoteIdentifierKey)
            didAccessValue(forKey: "remoteIdentifier")
            return value
        }

        set {
            willChangeValue(forKey: Self.remoteIdentifierKey)
            setTransientUUID(newValue, forKey: Self.remoteIdentifierKey)
            didChangeValue(forKey: Self.remoteIdentifierKey)
            updatePrimaryKey(remoteIdentifier: newValue, domain: domain)
        }
    }

    var objectId: Any {
        objectID
    }

    /// combination of domain and remoteIdentifier
    @NSManaged private var primaryKey: String

    private func updatePrimaryKey(remoteIdentifier: UUID?, domain: String?) {
        guard entity.attributesByName["primaryKey"] != nil else {
            // trying to access primaryKey property from older model - tests
            return
        }
        primaryKey = Self.primaryKey(from: remoteIdentifier, domain: domain)
    }

    @objc(setImageData:size:)
    func setImage(data: Data?, size: ProfileImageSize) {
        guard let imageData = data else {
            managedObjectContext?.zm_userImageCache?.removeAllUserImages(self)
            return
        }
        managedObjectContext?.zm_userImageCache?.setUserImage(self, imageData: imageData, size: size)

        if let uiContext = managedObjectContext?.zm_userInterface {
            let changedKey = size == .preview ? #keyPath(ZMUser.previewImageData) : #keyPath(ZMUser.completeImageData)
            NotificationDispatcher.notifyNonCoreDataChanges(
                objectID: objectID,
                changedKeys: [changedKey],
                uiContext: uiContext
            )
        }
    }

    func imageData(
        for size: ProfileImageSize,
        queue: DispatchQueue,
        completion: @escaping (_ imageData: Data?) -> Void
    ) {
        managedObjectContext?.zm_userImageCache?.userImage(self, size: size, queue: queue, completion: completion)
    }

    @objc
    func imageData(for size: ProfileImageSize) -> Data? {
        managedObjectContext?.zm_userImageCache?.userImage(self, size: size)
    }

    static var previewImageDownloadFilter: NSPredicate {
        let assetIdExists = NSPredicate(format: "(%K != nil)", ZMUser.previewProfileAssetIdentifierKey)
        let assetIdIsValid = NSPredicate { user, _ -> Bool in
            guard let user = user as? ZMUser else { return false }
            return user.previewProfileAssetIdentifier?.isValidAssetID ?? false
        }
        let notCached = NSPredicate { user, _ -> Bool in
            guard let user = user as? ZMUser else { return false }
            return user.imageSmallProfileData == nil
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: [assetIdExists, assetIdIsValid, notCached])
    }

    static var completeImageDownloadFilter: NSPredicate {
        let assetIdExists = NSPredicate(format: "(%K != nil)", ZMUser.completeProfileAssetIdentifierKey)
        let assetIdIsValid = NSPredicate { user, _ -> Bool in
            guard let user = user as? ZMUser else { return false }
            return user.completeProfileAssetIdentifier?.isValidAssetID ?? false
        }
        let notCached = NSPredicate { user, _ -> Bool in
            guard let user = user as? ZMUser else { return false }
            return user.imageMediumData == nil
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: [assetIdExists, assetIdIsValid, notCached])
    }

    func updateAndSyncProfileAssetIdentifiers(previewIdentifier: String, completeIdentifier: String) {
        guard isSelfUser else { return }
        previewProfileAssetIdentifier = previewIdentifier
        completeProfileAssetIdentifier = completeIdentifier
        setLocallyModifiedKeys([ZMUser.previewProfileAssetIdentifierKey, ZMUser.completeProfileAssetIdentifierKey])
    }

    @objc
    func updateAssetData(with assets: NSArray?, authoritative: Bool) {
        guard !hasLocalModifications(forKeys: [
            ZMUser.previewProfileAssetIdentifierKey,
            ZMUser.completeProfileAssetIdentifierKey
        ]) else { return }
        guard let assets = assets as? [[String: String]], !assets.isEmpty else {
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

    @objc
    func requestPreviewProfileImage() {
        guard let moc = managedObjectContext, moc.zm_isUserInterfaceContext, !moc.zm_userImageCache.hasUserImage(
            self,
            size: .preview
        ) else { return }

        NotificationInContext(
            name: .userDidRequestPreviewAsset,
            context: moc.notificationContext,
            object: objectID
        ).post()
    }

    @objc
    func requestCompleteProfileImage() {
        guard let moc = managedObjectContext, moc.zm_isUserInterfaceContext, !moc.zm_userImageCache.hasUserImage(
            self,
            size: .complete
        ) else { return }

        NotificationInContext(
            name: .userDidRequestCompleteAsset,
            context: moc.notificationContext,
            object: objectID
        ).post()
    }

    /// Mark the user's account as having been deleted. This will also remove the user from any conversations he/she
    /// is still a participant of and add a system message to 1:1 conversations.
    @objc
    func markAccountAsDeleted(at timestamp: Date) {
        isAccountDeleted = true
        removeFromAllGroupConversations(at: timestamp)
        addSystemMessageInOneOnOneConversation(at: timestamp)
    }

    /// Remove user from all group conversations he is a participant of
    private func removeFromAllGroupConversations(at timestamp: Date) {
        let allGroupConversations: [ZMConversation] = participantRoles.compactMap {
            guard $0.conversation?.conversationType == .group else {
                return nil
            }
            return $0.conversation
        }

        allGroupConversations.forEach { conversation in
            if isTeamMember, conversation.team == team {
                conversation.appendTeamMemberRemovedSystemMessage(user: self, at: timestamp)
            } else {
                conversation.appendParticipantRemovedSystemMessage(user: self, at: timestamp)
            }
            conversation.removeParticipantAndUpdateConversationState(user: self, initiatingUser: self)
        }
    }

    private func addSystemMessageInOneOnOneConversation(at timestamp: Date) {
        let conversations: [ZMConversation] = participantRoles.compactMap {
            guard $0.conversation?.conversationType == .oneOnOne else {
                return nil
            }
            return $0.conversation
        }

        conversations.forEach { conversation in
            conversation.appendUserRemovedFromTeamSystemMessage(user: self, at: timestamp)
        }
    }

}

public extension ZMUser {
    // MARK: - Participant role

    @objc var conversations: Set<ZMConversation> {
        Set(participantRoles.compactMap(\.conversation))
    }
}

extension NSManagedObject: SafeForLoggingStringConvertible {
    public var safeForLoggingDescription: String {
        let moc: String = managedObjectContext?.description ?? "nil"

        return "\(type(of: self)) \(Unmanaged.passUnretained(self).toOpaque()): moc=\(moc) objectID=\(objectID)"
    }
}

public extension ZMUser {

    /// The initials e.g. "JS" for "John Smith"
    @objc var initials: String? {
        PersonName.person(withName: name ?? "", schemeTagger: nil).initials
    }
}

extension ZMUser: UserConnections {

    public func connect(completion: @escaping (Error?) -> Void) {
        ZMUser.selfUser(in: managedObjectContext!).sendConnectionRequest(to: self) { result in
            switch result {
            case .success:
                completion(nil)
            case let .failure(error):
                completion(error)
            }
        }
    }

    public enum AcceptConnectionError: Error {

        case invalidState
        case unableToSwitchToMLS

    }

    public func accept(completion: @escaping (Error?) -> Void) {
        guard let syncContext = managedObjectContext?.zm_sync else {
            completion(AcceptConnectionError.invalidState)
            return
        }

        let mlsService = syncContext.performAndWait { syncContext.mlsService }
        let migrator = mlsService.map(OneOnOneMigrator.init(mlsService:))
        let resolver = LegacyOneOnOneResolver(migrator: migrator, isMLSEnabled: isMLSEnabled())

        accept(
            oneOnOneResolver: resolver,
            context: syncContext,
            completion: completion
        )
    }

    func accept(
        oneOnOneResolver: OneOnOneResolverInterface,
        context: NSManagedObjectContext,
        completion: @escaping (Error?) -> Void
    ) {
        guard
            let connection,
            let userID = remoteIdentifier,
            let domain = domain ?? managedObjectContext?.localDomain
        else {
            completion(AcceptConnectionError.invalidState)
            return
        }

        connection.updateStatus(.accepted) { result in
            switch result {
            case .success:
                Task {
                    do {
                        try await oneOnOneResolver.resolveOneOnOneConversation(
                            with: QualifiedID(uuid: userID, domain: domain),
                            in: context
                        )

                        await context.perform {
                            _ = context.saveOrRollback()
                        }

                        await MainActor.run {
                            completion(nil)
                        }
                    } catch {
                        await MainActor.run {
                            completion(error)
                        }
                    }
                }

            case let .failure(error):
                completion(error)
            }
        }
    }

    public func ignore(completion: @escaping (Error?) -> Void) {
        connection?.updateStatus(.ignored, completion: { result in
            switch result {
            case .success:
                completion(nil)
            case let .failure(error):
                completion(error)
            }
        })
    }

    public func block(completion: @escaping (Error?) -> Void) {
        connection?.updateStatus(.blocked, completion: { result in
            switch result {
            case .success:
                completion(nil)
            case let .failure(error):
                completion(error)
            }
        })
    }

    public func cancelConnectionRequest(completion: @escaping (Error?) -> Void) {
        connection?.updateStatus(.cancelled, completion: { result in
            switch result {
            case .success:
                completion(nil)
            case let .failure(error):
                completion(error)
            }
        })
    }

}
