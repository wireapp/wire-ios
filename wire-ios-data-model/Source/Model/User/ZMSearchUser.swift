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

import Foundation

extension Notification.Name {
    public static let searchUserDidRequestPreviewAsset = Notification.Name("SearchUserDidRequestPreviewAsset")
    public static let searchUserDidRequestCompleteAsset = Notification.Name("SearchUserDidRequestCompleteAsset")
}

private enum ResponseKey: String {
    case pictureTag = "tag"
    case pictures = "picture"
    case id
    case pictureInfo = "info"
    case assets
    case assetSize = "size"
    case assetKey = "key"
    case assetType = "type"
}

private enum ImageTag: String {
    case smallProfile
    case medium
}

private enum AssetSize: String {
    case preview
    case complete
}

private enum AssetKind: String {
    case image
}

public struct SearchUserAssetKeys {
    public let preview: String?
    public let complete: String?

    init?(payload: [String: Any]) {
        if let assetsPayload = payload[ResponseKey.assets.rawValue] as? [[String: Any]], !assetsPayload.isEmpty {
            var previewKey: String?, completeKey: String?

            for asset in assetsPayload {
                guard let size = (asset[ResponseKey.assetSize.rawValue] as? String).flatMap(AssetSize.init),
                      let key = asset[ResponseKey.assetKey.rawValue] as? String,
                      let type = (asset[ResponseKey.assetType.rawValue] as? String).flatMap(AssetKind.init),
                      type == .image else { continue }

                switch size {
                case .preview: previewKey = key
                case .complete: completeKey = key
                }
            }

            if previewKey != nil || completeKey != nil {
                self.preview = previewKey
                self.complete = completeKey
                return
            }
        }

        return nil
    }
}

extension ZMSearchUser: SearchServiceUser {
    public var serviceIdentifier: String? {
        remoteIdentifier?.transportString()
    }
}

// MARK: NSManagedObjectContext

@objc
public class ZMSearchUser: NSObject, UserType {
    public var providerIdentifier: String?
    public var summary: String?
    public var assetKeys: SearchUserAssetKeys?
    public var remoteIdentifier: UUID!
    public var teamIdentifier: UUID?
    @objc public var contact: ZMAddressBookContact?
    @objc public var user: ZMUser?
    public private(set) var hasDownloadedFullUserProfile = false

    fileprivate weak var contextProvider: ContextProvider?
    private let searchUsersCache: SearchUsersCache?

    fileprivate var internalDomain: String?
    fileprivate var internalName: String
    fileprivate var internalInitials: String?
    fileprivate var internalHandle: String?
    fileprivate var internalIsConnected = false
    fileprivate var internalIsTeamMember = false
    fileprivate var internalTeamCreatedBy: UUID?
    fileprivate var internalTeamPermissions: Permissions?
    fileprivate var internalAccentColorValue: ZMAccentColorRawValue
    fileprivate var internalPendingApprovalByOtherUser = false
    fileprivate var internalConnectionRequestMessage: String?
    fileprivate var internalPreviewImageData: Data?
    fileprivate var internalCompleteImageData: Data?
    fileprivate var internalIsAccountDeleted: Bool?

    @objc public var hasTeam: Bool {
        user?.hasTeam ?? false
    }

    /// Whether all user's devices are verified by the selfUser
    public var isTrusted: Bool {
        user?.isTrusted ?? false
    }

    public var teamCreatedBy: UUID? {
        user?.membership?.createdBy?.remoteIdentifier ?? internalTeamCreatedBy
    }

    public var emailAddress: String? {
        user?.emailAddress
    }

    public var phoneNumber: String? {
        user?.phoneNumber
    }

    public var domain: String? {
        user?.domain ?? internalDomain
    }

    public var name: String? {
        user?.name ?? internalName
    }

    public var handle: String? {
        user?.handle ?? internalHandle
    }

    public var initials: String? {
        user?.initials ?? internalInitials
    }

    public var availability: Availability {
        get { user?.availability ?? .none }
        set { user?.availability = newValue }
    }

    public var isFederated: Bool {
        guard let contextProvider else {
            return false
        }

        return ZMUser.selfUser(inUserSession: contextProvider).isFederating(with: self)
    }

    public var isSelfUser: Bool {
        guard let user else { return false }

        return user.isSelfUser
    }

    public var membership: Member? {
        user?.membership
    }

    public var teamName: String? {
        user?.teamName
    }

    public var isTeamMember: Bool {
        if let user {
            user.isTeamMember
        } else {
            internalIsTeamMember
        }
    }

    public var isPendingMetadataRefresh: Bool {
        guard let user else { return false }

        return user.isPendingMetadataRefresh
    }

    public var hasDigitalSignatureEnabled: Bool {
        user?.hasDigitalSignatureEnabled ?? false
    }

    public var teamRole: TeamRole {
        guard let user else {
            return (internalTeamPermissions?.rawValue).flatMap(TeamRole.init(rawPermissions:)) ?? .none
        }

        return user.teamRole
    }

    public var isServiceUser: Bool {
        providerIdentifier != nil
    }

    public var usesCompanyLogin: Bool {
        user?.usesCompanyLogin == true
    }

    public var readReceiptsEnabled: Bool {
        user?.readReceiptsEnabled ?? false
    }

    public var activeConversations: Set<ZMConversation> {
        user?.activeConversations ?? Set()
    }

    public var allClients: [UserClientType] {
        user?.allClients ?? []
    }

    public var isVerified: Bool {
        user?.isVerified ?? false
    }

    public var managedByWire: Bool {
        user?.managedByWire != false
    }

    public var isPendingApprovalByOtherUser: Bool {
        if let user {
            user.isPendingApprovalByOtherUser
        } else {
            internalPendingApprovalByOtherUser
        }
    }

    public var isConnected: Bool {
        get {
            if let user {
                user.isConnected
            } else {
                internalIsConnected
            }
        }
        set {
            internalIsConnected = newValue
        }
    }

    public var oneToOneConversation: ZMConversation? {
        if isTeamMember, let uiContext = contextProvider?.viewContext {
            materialize(in: uiContext)?.oneToOneConversation
        } else {
            user?.oneToOneConversation
        }
    }

    public var isBlocked: Bool {
        user?.isBlocked == true
    }

    public var blockState: ZMBlockState {
        user?.blockState ?? .none
    }

    public var isExpired: Bool {
        user?.isExpired == true
    }

    public var isIgnored: Bool {
        user?.isIgnored == true
    }

    public var isPendingApprovalBySelfUser: Bool {
        user?.isPendingApprovalBySelfUser == true
    }

    public var isAccountDeleted: Bool {
        if let isDeleted = internalIsAccountDeleted {
            return isDeleted
        } else if let user {
            return user.isAccountDeleted
        }

        return false
    }

    public var isUnderLegalHold: Bool {
        user?.isUnderLegalHold == true
    }

    public var accentColorValue: ZMAccentColorRawValue {
        if let user {
            user.accentColorValue
        } else {
            internalAccentColorValue
        }
    }

    public var zmAccentColor: ZMAccentColor? {
        .from(rawValue: accentColorValue)
    }

    public var isWirelessUser: Bool {
        user?.isWirelessUser ?? false
    }

    public var expiresAfter: TimeInterval {
        user?.expiresAfter ?? 0
    }

    public var connectionRequestMessage: String? {
        user?.connectionRequestMessage ?? internalConnectionRequestMessage
    }

    public var previewImageData: Data? {
        user?.previewImageData ?? internalPreviewImageData
    }

    public var completeImageData: Data? {
        user?.completeImageData ?? internalCompleteImageData
    }

    public var richProfile: [UserRichProfileField] {
        user?.richProfile ?? []
    }

    public func canAccessCompanyInformation(of otherUser: UserType) -> Bool {
        user?.canAccessCompanyInformation(of: otherUser) ?? false
    }

    public func canCreateConversation(type: ZMConversationType) -> Bool {
        user?.canCreateConversation(type: type) ?? false
    }

    public var canCreateService: Bool {
        user?.canCreateService ?? false
    }

    public var canManageTeam: Bool {
        user?.canManageTeam ?? false
    }

    public func canAddService(to conversation: ZMConversation) -> Bool {
        user?.canAddService(to: conversation) == true
    }

    public func canRemoveService(from conversation: ZMConversation) -> Bool {
        user?.canRemoveService(from: conversation) == true
    }

    public func canAddUser(to conversation: ConversationLike) -> Bool {
        user?.canAddUser(to: conversation) == true
    }

    public func canRemoveUser(from conversation: ZMConversation) -> Bool {
        user?.canRemoveUser(from: conversation) == true
    }

    public func canDeleteConversation(_ conversation: ZMConversation) -> Bool {
        user?.canDeleteConversation(conversation) == true
    }

    public func canModifyTitle(in conversation: ConversationLike) -> Bool {
        user?.canModifyTitle(in: conversation) == true
    }

    public func canModifyOtherMember(in conversation: ZMConversation) -> Bool {
        user?.canModifyOtherMember(in: conversation) == true
    }

    public func canModifyEphemeralSettings(in conversation: ConversationLike) -> Bool {
        user?.canModifyEphemeralSettings(in: conversation) == true
    }

    public func canModifyReadReceiptSettings(in conversation: ConversationLike) -> Bool {
        user?.canModifyReadReceiptSettings(in: conversation) == true
    }

    public func canModifyNotificationSettings(in conversation: ConversationLike) -> Bool {
        user?.canModifyNotificationSettings(in: conversation) == true
    }

    public func canModifyAccessControlSettings(in conversation: ConversationLike) -> Bool {
        user?.canModifyAccessControlSettings(in: conversation) == true
    }

    public func canLeave(_ conversation: ZMConversation) -> Bool {
        user?.canLeave(conversation) == true
    }

    public func isGroupAdmin(in conversation: ConversationLike) -> Bool {
        user?.isGroupAdmin(in: conversation) == true
    }

    public var canCreateMLSGroups: Bool {
        user?.canCreateMLSGroups == true
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let otherSearchUser = object as? ZMSearchUser else { return false }

        if let lhsRemoteIdentifier = remoteIdentifier, let rhsRemoteIdentifier = otherSearchUser.remoteIdentifier {
            return lhsRemoteIdentifier == rhsRemoteIdentifier
        } else if let lhsContact = contact, let rhsContact = otherSearchUser.contact, otherSearchUser.user == nil {
            return lhsContact == rhsContact
        }

        return false
    }

    override public var hash: Int {
        remoteIdentifier?.hashValue ?? super.hash
    }

    public static func searchUsers(
        from payloadArray: [[String: Any]],
        contextProvider: ContextProvider,
        searchUsersCache: SearchUsersCache?
    ) -> [ZMSearchUser] {
        payloadArray.compactMap {
            searchUser(
                from: $0,
                contextProvider: contextProvider,
                searchUsersCache: searchUsersCache
            )
        }
    }

    public static func searchUser(
        from payload: [String: Any],
        contextProvider: ContextProvider,
        searchUsersCache: SearchUsersCache?
    ) -> ZMSearchUser? {
        guard
            let uuidString = payload["id"] as? String,
            let remoteIdentifier = UUID(uuidString: uuidString)
        else { return nil }

        let domain = payload.optionalDictionary(forKey: "qualified_id")?.string(forKey: "domain")
        let localUser = ZMUser.fetch(
            with: remoteIdentifier,
            domain: domain,
            in: contextProvider.viewContext
        )

        if let searchUser = searchUsersCache?.object(forKey: remoteIdentifier as NSUUID) {
            searchUser.user = localUser
            return searchUser
        } else {
            return ZMSearchUser(
                from: payload,
                contextProvider: contextProvider,
                user: localUser,
                searchUsersCache: searchUsersCache
            )
        }
    }

    @objc
    public init(
        contextProvider: ContextProvider,
        name: String,
        handle: String?,
        accentColor: ZMAccentColor?,
        remoteIdentifier: UUID?,
        domain: String? = nil,
        teamIdentifier: UUID? = nil,
        user existingUser: ZMUser? = nil,
        contact: ZMAddressBookContact? = nil,
        searchUsersCache: SearchUsersCache?
    ) {
        let personName = PersonName.person(withName: name, schemeTagger: nil)

        self.internalName = name
        self.internalHandle = handle
        self.internalInitials = personName.initials
        self.internalAccentColorValue = accentColor?.rawValue ?? 0
        self.user = existingUser
        self.internalDomain = domain
        self.remoteIdentifier = existingUser?.remoteIdentifier ?? remoteIdentifier
        self.teamIdentifier = existingUser?.teamIdentifier ?? teamIdentifier
        self.contact = contact
        self.contextProvider = contextProvider
        self.searchUsersCache = searchUsersCache

        let selfUser = ZMUser.selfUser(inUserSession: contextProvider)
        self.internalIsTeamMember = teamIdentifier != nil && selfUser.teamIdentifier == teamIdentifier
        self.internalIsConnected = internalIsTeamMember

        super.init()

        if let remoteIdentifier = self.remoteIdentifier {
            searchUsersCache?.setObject(self, forKey: remoteIdentifier as NSUUID)
        }
    }

    @objc
    public convenience init(
        contextProvider: ContextProvider,
        user: ZMUser,
        searchUsersCache: SearchUsersCache?
    ) {
        self.init(
            contextProvider: contextProvider,
            name: user.name ?? "",
            handle: user.handle,
            accentColor: user.zmAccentColor,
            remoteIdentifier: user.remoteIdentifier,
            domain: user.domain,
            teamIdentifier: user.teamIdentifier,
            user: user,
            searchUsersCache: searchUsersCache
        )
    }

    @objc
    public convenience init(
        contextProvider: ContextProvider,
        contact: ZMAddressBookContact,
        user: ZMUser? = nil,
        searchUsersCache: SearchUsersCache?
    ) {
        self.init(
            contextProvider: contextProvider,
            name: contact.name,
            handle: user?.handle,
            accentColor: nil,
            remoteIdentifier: user?.remoteIdentifier,
            domain: user?.domain,
            teamIdentifier: user?.teamIdentifier,
            user: user,
            contact: contact,
            searchUsersCache: searchUsersCache
        )
    }

    convenience init?(
        from payload: [String: Any],
        contextProvider: ContextProvider,
        user: ZMUser? = nil,
        searchUsersCache: SearchUsersCache?
    ) {
        guard
            let uuidString = payload["id"] as? String,
            let remoteIdentifier = UUID(uuidString: uuidString),
            let name = payload["name"] as? String else {
            return nil
        }

        let teamIdentifier = (payload["team"] as? String).flatMap { UUID(uuidString: $0) }
        let handle = payload["handle"] as? String
        let qualifiedID = payload["qualified_id"] as? [String: Any]
        let domain = qualifiedID?["domain"] as? String
        let accentColorRawValue = (payload["accent_id"] as? NSNumber)?.int16Value ?? 0

        self.init(
            contextProvider: contextProvider,
            name: name,
            handle: handle,
            accentColor: .from(rawValue: accentColorRawValue) ?? .default,
            remoteIdentifier: remoteIdentifier,
            domain: domain,
            teamIdentifier: teamIdentifier,
            user: user,
            searchUsersCache: searchUsersCache
        )

        self.providerIdentifier = payload["provider"] as? String
        self.summary = payload["summary"] as? String
        self.assetKeys = SearchUserAssetKeys(payload: payload)
        self.internalIsAccountDeleted = payload["deleted"] as? Bool
    }

    public var smallProfileImageCacheKey: String? {
        if let user {
            return user.smallProfileImageCacheKey
        } else if let remoteIdentifier {
            return "\(remoteIdentifier.transportString())_preview"
        }

        return nil
    }

    public var mediumProfileImageCacheKey: String? {
        if let user {
            return user.mediumProfileImageCacheKey
        } else if let remoteIdentifier {
            return "\(remoteIdentifier.transportString())_complete"
        }

        return nil
    }

    public func refreshData() {
        user?.refreshData()
    }

    public func refreshRichProfile() {
        user?.refreshRichProfile()
    }

    public func refreshMembership() {
        user?.refreshMembership()
    }

    public func refreshTeamData() {
        user?.refreshTeamData()
    }

    public func connect(completion: @escaping (Error?) -> Void) {
        let selfUser = ZMUser.selfUser(inUserSession: contextProvider!)
        selfUser.sendConnectionRequest(to: self) { [weak self] result in
            switch result {
            case .success:
                self?.internalPendingApprovalByOtherUser = true
                self?.updateLocalUser()
                self?.notifySearchUserChanged()
                completion(nil)
            case let .failure(error):
                completion(error)
            }
        }
    }

    private func updateLocalUser() {
        guard
            let userID = remoteIdentifier,
            let viewContext = contextProvider?.viewContext
        else {
            return
        }

        user = ZMUser.fetch(with: userID, domain: domain, in: viewContext)
    }

    private func notifySearchUserChanged() {
        contextProvider?.viewContext.searchUserObserverCenter.notifyUpdatedSearchUser(self)
    }

    public func accept(completion: @escaping (Error?) -> Void) {
        user?.accept(completion: completion)
    }

    public func ignore(completion: @escaping (Error?) -> Void) {
        user?.ignore(completion: completion)
    }

    public func block(completion: @escaping (Error?) -> Void) {
        user?.block(completion: completion)
    }

    public func cancelConnectionRequest(completion: @escaping (Error?) -> Void) {
        user?.cancelConnectionRequest(completion: completion)
    }

    @objc public var canBeConnected: Bool {
        guard !isServiceUser else { return false }

        if let user {
            return user.canBeConnected
        } else {
            return !internalIsConnected && remoteIdentifier != nil
        }
    }

    public func requestPreviewProfileImage() {
        guard previewImageData == nil else { return }

        if let user {
            user.requestPreviewProfileImage()
        } else if let notificationContext = contextProvider?.viewContext.notificationContext {
            NotificationInContext(
                name: .searchUserDidRequestPreviewAsset,
                context: notificationContext,
                object: self,
                userInfo: nil
            ).post()
        }
    }

    public func requestCompleteProfileImage() {
        guard completeImageData == nil else { return }

        if let user {
            user.requestCompleteProfileImage()
        } else if let notificationContext = contextProvider?.viewContext.notificationContext {
            NotificationInContext(
                name: .searchUserDidRequestCompleteAsset,
                context: notificationContext,
                object: self,
                userInfo: nil
            ).post()
        }
    }

    public func isGuest(in conversation: ConversationLike) -> Bool {
        guard let user else { return false }

        return user.isGuest(in: conversation)
    }

    public func imageData(for size: ProfileImageSize) -> Data? {
        if let user {
            user.imageData(for: size)
        } else {
            size == .complete ? completeImageData : previewImageData
        }
    }

    public func imageData(for size: ProfileImageSize, queue: DispatchQueue, completion: @escaping (Data?) -> Void) {
        if let user {
            user.imageData(for: size, queue: queue, completion: completion)
        } else {
            let imageData = size == .complete ? completeImageData : previewImageData

            queue.async {
                completion(imageData)
            }
        }
    }

    @objc
    public func updateImageData(for size: ProfileImageSize, imageData: Data) {
        switch size {
        case .preview:
            internalPreviewImageData = imageData
        case .complete:
            internalCompleteImageData = imageData
        }

        contextProvider?.viewContext.searchUserObserverCenter.notifyUpdatedSearchUser(self)
    }

    public func update(from payload: [String: Any]) {
        hasDownloadedFullUserProfile = true

        assetKeys = SearchUserAssetKeys(payload: payload)
    }

    public func reportImageDataHasBeenDeleted() {
        assetKeys = nil
    }

    public func updateWithTeamMembership(permissions: Permissions?, createdBy: UUID?) {
        internalTeamPermissions = permissions
        internalTeamCreatedBy = createdBy
    }
}
