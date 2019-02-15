//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

public extension Notification.Name {
    static let searchUserDidRequestPreviewAsset = Notification.Name("SearchUserDidRequestPreviewAsset")
    static let searchUserDidRequestCompleteAsset = Notification.Name("SearchUserDidRequestCompleteAsset")
}

fileprivate enum ResponseKey: String {
    case pictureTag = "tag"
    case pictures = "picture"
    case id
    case pictureInfo = "info"
    case assets
    case assetSize = "size"
    case assetKey = "key"
    case assetType = "type"
}


fileprivate enum ImageTag: String {
    case smallProfile
    case medium
}

fileprivate enum AssetSize: String {
    case preview
    case complete
}

fileprivate enum AssetType: String {
    case image
}

/// Either we have assetKeys (Strings) or old style legacy UUIDs.
public enum SearchUserAssetKeys {
    case asset(preview: String?, complete: String?)
    case legacy(small: UUID?, medium: UUID?)
    
    init?(payload: [String: Any]) {
        // V3
        if let assetsPayload = payload[ResponseKey.assets.rawValue] as? [[String : Any]], assetsPayload.count > 0 {
            var smallKey: String?, completeKey: String?
            
            
            for asset in assetsPayload {
                guard let size = (asset[ResponseKey.assetSize.rawValue] as? String).flatMap(AssetSize.init),
                    let key = asset[ResponseKey.assetKey.rawValue] as? String,
                    let type = (asset[ResponseKey.assetType.rawValue] as? String).flatMap(AssetType.init),
                    type == .image else { continue }
                
                switch size {
                case .preview: smallKey = key
                case .complete: completeKey = key
                }
            }
            
            if nil != smallKey || nil != completeKey {
                self = .asset(preview: smallKey, complete: completeKey)
                return
            }
        }
            // Legacy
        else if let pictures = payload[ResponseKey.pictures.rawValue] as? [[String : Any]] {
            var smallId: UUID?, mediumId: UUID?
            
            for pictureData in pictures {
                guard let info = (pictureData[ResponseKey.pictureInfo.rawValue] as? [String : Any]),
                    let tag = (info[ResponseKey.pictureTag.rawValue] as? String).flatMap(ImageTag.init),
                    let uuid = (pictureData[ResponseKey.id.rawValue] as? String).flatMap(UUID.init) else { continue }
                
                switch tag {
                case .smallProfile: smallId = uuid
                case .medium: mediumId = uuid
                }
            }
            
            if smallId != nil || mediumId != nil {
                self = .legacy(small: smallId, medium: mediumId)
                return
            }
        }
        
        return nil
    }
    
}

extension ZMSearchUser: SearchServiceUser {
    
    public var serviceIdentifier: String? {
        return remoteIdentifier?.transportString()
    }
    
}

// MARK: NSManagedObjectContext

let NSManagedObjectContextSearchUserCacheKey = "zm_searchUserCache"
extension NSManagedObjectContext
{
    @objc
    public var zm_searchUserCache: NSCache<NSUUID, ZMSearchUser>? {
        get {
            guard zm_isUserInterfaceContext else { return nil }
            return self.userInfo[NSManagedObjectContextSearchUserCacheKey] as? NSCache
        }
        
        set {
            guard zm_isUserInterfaceContext else { return }
            self.userInfo[NSManagedObjectContextSearchUserCacheKey] = newValue
        }
    }
}


@objc
public class ZMSearchUser: NSObject, UserType, UserConnectionType {
    
    public var providerIdentifier: String?
    public var summary: String?
    public var assetKeys: SearchUserAssetKeys?
    public var remoteIdentifier: UUID?
    @objc public var contact: ZMAddressBookContact?
    @objc public var user: ZMUser?
    public private(set) var hasDownloadedFullUserProfile: Bool = false
    
    fileprivate weak var contextProvider: ZMManagedObjectContextProvider?
    fileprivate var internalName: String
    fileprivate var internalDisplayName: String?
    fileprivate var internalInitials: String?
    fileprivate var internalHandle: String?
    fileprivate var internalIsConnected: Bool = false
    fileprivate var internalAccentColorValue: ZMAccentColor
    fileprivate var internalPendingApprovalByOtherUser: Bool = false
    fileprivate var internalConnectionRequestMessage: String?
    fileprivate var internalPreviewImageData: Data?
    fileprivate var internalCompleteImageData: Data?
    
    public var name: String? {
        get {
            return user != nil ? user?.name : internalName
        }
    }
    
    public var displayName: String {
        get {
            return user != nil ? user!.displayName : internalDisplayName ?? ""
        }
    }
    
    public var handle: String? {
        get {
            return user != nil ? user?.handle : internalHandle
        }
    }
    
    public var initials: String? {
        get {
            return user != nil ? user?.initials : internalInitials
        }
    }
    
    public var isSelfUser: Bool {
        guard let user = user else { return false }
        
        return user.isSelfUser
    }
    
    public var isTeamMember: Bool {
        guard let user = user else { return false }
        
        return user.isTeamMember
    }
    
    public var teamRole: TeamRole {
        guard let user = user else { return .none }
        
        return user.teamRole
    }
    
    public var isServiceUser: Bool {
        return providerIdentifier != nil
    }
    
    public var isPendingApprovalByOtherUser: Bool {
        if let user = user {
            return user.isPendingApprovalByOtherUser
        } else {
            return internalPendingApprovalByOtherUser
        }
    }
    
    public var isConnected: Bool {
        get {
            if let user = user {
                return user.isConnected
            } else {
                return internalIsConnected
            }
        }
        set {
            internalIsConnected = newValue
        }
    }
    
    public var isAccountDeleted: Bool {
        guard let user = user else { return false }
        
        return user.isAccountDeleted
    }
    
    public var accentColorValue: ZMAccentColor {
        get {
            if let user = user {
                return user.accentColorValue
            } else {
                return internalAccentColorValue
            }
        }
    }
    
    public var connectionRequestMessage: String? {
        get {
            if let user = user {
                return user.connectionRequestMessage
            } else {
                return internalConnectionRequestMessage
            }
        }
    }
    
    public var previewImageData: Data? {
        if let user = user {
            return user.previewImageData
        } else {
            return internalPreviewImageData
        }
    }
    
    public var completeImageData: Data? {
        if let user = user {
            return user.completeImageData
        } else {
            return internalCompleteImageData
        }
    }
    
    public var extendedMetadata: [[String : String]]? {
        return user?.extendedMetadata
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let otherSearchUser = object as? ZMSearchUser else { return false }
        
        if let lhsRemoteIdentifier = remoteIdentifier, let rhsRemoteIdentifier = otherSearchUser.remoteIdentifier {
            return lhsRemoteIdentifier == rhsRemoteIdentifier
        } else if let lhsContact = contact, let rhsContact = otherSearchUser.contact, otherSearchUser.user == nil {
            return lhsContact == rhsContact
        }
        
        return false
    }
    
    public override var hash: Int {
        get {
            return remoteIdentifier?.hashValue ?? super.hash
        }
    }
        
    public static func searchUsers(from payloadArray: [Dictionary<String, Any>], contextProvider: ZMManagedObjectContextProvider) -> [ZMSearchUser] {
        return payloadArray.compactMap({ searchUser(from: $0, contextProvider: contextProvider) })
    }
    
    public static func searchUser(from payload: [String : Any], contextProvider: ZMManagedObjectContextProvider) -> ZMSearchUser? {
        guard let uuidString = payload["id"] as? String, let remoteIdentifier = UUID(uuidString: uuidString) else { return nil }
        
        let localUser = ZMUser(remoteID: remoteIdentifier, createIfNeeded: false, in: contextProvider.managedObjectContext)
        
        if let searchUser = contextProvider.managedObjectContext.zm_searchUserCache?.object(forKey: remoteIdentifier as NSUUID) {
            searchUser.user = localUser
            return searchUser
        } else {
            return ZMSearchUser(from: payload, contextProvider: contextProvider, user: localUser)
        }
    }
    
    @objc
    public init(contextProvider: ZMManagedObjectContextProvider, name: String, handle: String?, accentColor: ZMAccentColor, remoteIdentifier: UUID?, user existingUser: ZMUser? = nil, contact: ZMAddressBookContact? = nil) {
                
        let personName = PersonName.person(withName: name, schemeTagger: nil)
        
        self.internalName = name
        self.internalHandle = handle
        self.internalInitials = personName.initials
        self.internalDisplayName = personName.givenName
        self.internalAccentColorValue = accentColor
        self.user = existingUser
        self.remoteIdentifier = existingUser?.remoteIdentifier ?? remoteIdentifier
        self.contact = contact
        self.contextProvider = contextProvider
        self.internalIsConnected = false
        
        super.init()
        
        if let remoteIdentifier = self.remoteIdentifier {
            contextProvider.managedObjectContext.zm_searchUserCache?.setObject(self, forKey: remoteIdentifier as NSUUID)
        }
    }
    
    @objc
    public convenience init(contextProvider: ZMManagedObjectContextProvider, user: ZMUser) {
        self.init(contextProvider: contextProvider, name: user.name ?? "", handle: user.handle, accentColor: user.accentColorValue, remoteIdentifier: user.remoteIdentifier, user: user)
    }
    
    @objc
    public convenience init(contextProvider: ZMManagedObjectContextProvider, contact: ZMAddressBookContact, user: ZMUser? = nil) {
        self.init(contextProvider: contextProvider, name: contact.name, handle: user?.handle, accentColor: .undefined, remoteIdentifier: user?.remoteIdentifier, user: user, contact: contact)
    }
    
    convenience init?(from payload: [String : Any], contextProvider: ZMManagedObjectContextProvider, user: ZMUser? = nil) {
        
        guard let uuidString = payload["id"] as? String, let remoteIdentifier = UUID(uuidString: uuidString),
              let name = payload["name"] as? String else { return nil }
        
        let handle = payload["handle"] as? String
        let accentColor = ZMUser.accentColor(fromPayloadValue: payload["accent_id"] as? NSNumber)
        
        self.init(contextProvider: contextProvider, name: name, handle: handle, accentColor: accentColor, remoteIdentifier: remoteIdentifier, user: user)
        
        self.providerIdentifier =  payload["provider"] as? String
        self.summary = payload["summary"] as? String
        self.assetKeys = SearchUserAssetKeys(payload: payload)
    }
    
    public var smallProfileImageCacheKey: String? {
        if let user = user {
            return user.smallProfileImageCacheKey
        } else if let remoteIdentifier = remoteIdentifier {
            return "\(remoteIdentifier.transportString())_preview"
        }
        
        return nil
    }
    
    public var mediumProfileImageCacheKey: String? {
        if let user = user {
            return user.mediumProfileImageCacheKey
        } else if let remoteIdentifier = remoteIdentifier {
            return "\(remoteIdentifier.transportString())_complete"
        }
        
        return nil
    }
    
    public func refreshData() {
        user?.refreshData()
    }
    
    public func connect(message: String) {
        
        guard canBeConnected else {
            return
        }
        
        internalPendingApprovalByOtherUser = true
        internalConnectionRequestMessage = message
        
        if let user = user {
            user.connect(message: message)
        } else {
            guard let remoteIdentifier = self.remoteIdentifier else { return }
            
            let name = self.name
            let accentColorValue = self.accentColorValue
            
            contextProvider?.syncManagedObjectContext.performGroupedBlock {
                guard let context = self.contextProvider?.syncManagedObjectContext,
                      let user = ZMUser(remoteID: remoteIdentifier, createIfNeeded: true, in: context) else { return }
                
                user.name = name
                user.accentColorValue = accentColorValue
                user.needsToBeUpdatedFromBackend = true
                
                let connection = ZMConnection.insertNewSentConnection(to: user)
                connection?.message = message
                context.saveOrRollback()
                
                let objectId = user.objectID
                self.contextProvider?.managedObjectContext.performGroupedBlock {
                    self.user = self.contextProvider?.managedObjectContext.object(with: objectId) as? ZMUser
                    self.contextProvider?.managedObjectContext.searchUserObserverCenter.notifyUpdatedSearchUser(self)
                }
            }
        }
    }
    
    @objc
    public var canBeConnected: Bool {
        guard !isServiceUser else { return false }
        
        if let user = user {
            return user.canBeConnected
        } else {
            return !internalIsConnected && remoteIdentifier != nil
        }
    }
    
    public func requestPreviewProfileImage() {
        guard previewImageData == nil else { return }
        
        if let user = self.user {
            user.requestPreviewProfileImage()
        } else if let notificationContext = contextProvider?.managedObjectContext?.notificationContext {
            NotificationInContext(name: .searchUserDidRequestPreviewAsset, context: notificationContext, object: self, userInfo: nil).post()
        }
    }
    
    public func requestCompleteProfileImage() {
        guard completeImageData == nil else { return }
        
        if let user = self.user {
            user.requestCompleteProfileImage()
        } else if let notificationContext = contextProvider?.managedObjectContext?.notificationContext {
            NotificationInContext(name: .searchUserDidRequestCompleteAsset, context: notificationContext, object: self, userInfo: nil).post()
        }
    }
    
    public func isGuest(in conversation: ZMConversation) -> Bool {
        guard let user = self.user else { return false }
        
        return user.isGuest(in: conversation)
    }
    
    public func imageData(for size: ProfileImageSize, queue: DispatchQueue, completion: @escaping (Data?) -> Void) {
        if let user = self.user {
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
        
        contextProvider?.managedObjectContext.searchUserObserverCenter.notifyUpdatedSearchUser(self)
    }
    
    public func update(from payload: [String : Any]) {
        hasDownloadedFullUserProfile = true
        
        self.assetKeys = SearchUserAssetKeys(payload: payload)
    }
    
    public func reportImageDataHasBeenDeleted() {
        self.assetKeys = nil
    }
    
}
