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

extension ZMUser: UserConnectionType { }

extension ZMUser: UserType {
    
    public func isGuest(in conversation: ZMConversation) -> Bool {
        return _isGuest(in: conversation)
    }
    
    public var previewImageData: Data? {
        return imageSmallProfileData
    }
    
    public var completeImageData: Data? {
        return imageMediumData
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
    
    internal var userKeyPath: String {
        switch self {
        case .preview:
            return #keyPath(ZMUser.imageSmallProfileData)
        case .complete:
            return #keyPath(ZMUser.imageMediumData)
        }
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

    /// Retrieves all users (excluding bots), having ZMConnectionStatusAccepted connection statuses.
    @objc static var predicateForConnectedNonBotUsers: NSPredicate {
        return predicateForUsers(withSearch: "", connectionStatuses: [ZMConnectionStatus.accepted.rawValue])
    }
    
    /// Retrieves connected users with name or handle matching search string
    ///
    /// - Parameter query: search string
    /// - Returns: predicate having search query and ZMConnectionStatusAccepted connection statuses
    @objc(predicateForConnectedUsersWithSearchString:)
    public static func predicateForConnectedUsers(withSearch query: String) -> NSPredicate {
        return predicateForUsers(withSearch: query, connectionStatuses: [ZMConnectionStatus.accepted.rawValue])
    }
    
    /// Retrieves all users with name or handle matching search string
    ///
    /// - Parameter query: search string
    /// - Returns: predicate having search query
    public static func predicateForAllUsers(withSearch query: String) -> NSPredicate {
        return predicateForUsers(withSearch: query, connectionStatuses: nil)
    }
    
    /// Retrieves users with name or handle matching search string, having one of given connection statuses
    ///
    /// - Parameters:
    ///   - query: search string
    ///   - connectionStatuses: an array of connections status of the users. E.g. for connected users it is [ZMConnectionStatus.accepted.rawValue]
    /// - Returns: predicate having search query and supplied connection statuses
    @objc(predicateForUsersWithSearchString:connectionStatusInArray:)
    public static func predicateForUsers(withSearch query: String, connectionStatuses: [Int16]? ) -> NSPredicate {
        var allPredicates = [[NSPredicate]]()
        if let statuses = connectionStatuses {
            allPredicates.append([predicateForUsers(withConnectionStatuses: statuses)])
        }

        let normalizedQuery = query.normalizedAndTrimmed()

        if !normalizedQuery.isEmpty {
            let namePredicate = NSPredicate(formatDictionary: [#keyPath(ZMUser.normalizedName) : "%K MATCHES %@"], matchingSearch: normalizedQuery)
            let normalizedHandle = normalizedQuery.strippingLeadingAtSign()
            let handlePredicate = NSPredicate(format: "%K BEGINSWITH %@", #keyPath(ZMUser.handle), normalizedHandle)
            allPredicates.append([namePredicate, handlePredicate].compactMap {$0})
        }
        
        let orPredicates = allPredicates.map { NSCompoundPredicate(orPredicateWithSubpredicates: $0) }
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: orPredicates)
    }
    
    @objc(predicateForUsersWithConnectionStatusInArray:)
    public static func predicateForUsers(withConnectionStatuses connectionStatuses: [Int16]) -> NSPredicate {
        return NSPredicate(format: "(%K IN (%@))", #keyPath(ZMUser.connection.status), connectionStatuses)
    }

}

fileprivate extension String {

    func normalizedAndTrimmed() -> String {
        guard let normalized = self.normalizedForSearch() as String? else { return "" }
        return normalized.trimmingCharacters(in: .whitespaces)
    }

    func strippingLeadingAtSign() -> String {
        guard hasPrefix("@") else { return self }
        var copy = self
        copy.remove(at: startIndex)
        return copy
    }

}

extension ZMUser {
    @objc static let previewProfileAssetIdentifierKey = #keyPath(ZMUser.previewProfileAssetIdentifier)
    @objc static let completeProfileAssetIdentifierKey = #keyPath(ZMUser.completeProfileAssetIdentifier)
    
    @NSManaged public var previewProfileAssetIdentifier: String?
    @NSManaged public var completeProfileAssetIdentifier: String?
    
    /// Conversation in which the user is active, according to the server
    @NSManaged var lastServerSyncedActiveConversations: NSOrderedSet
    
    /// Conversations created by this user
    @NSManaged var conversationsCreated: Set<ZMConversation>
    
    /// Team membership for this user
    @NSManaged public internal(set) var membership: Member?

    /// Reactions expressed by this user
    @NSManaged var reactions: Set<Reaction>
    
    /// System messages referencing this user
    @NSManaged var systemMessages: Set<ZMSystemMessage>
    
    @NSManaged var expiresAt: Date?
    
    @NSManaged public var usesCompanyLogin: Bool
    
    @objc(setImageData:size:)
    public func setImage(data: Data?, size: ProfileImageSize) {
        let key = size.userKeyPath
        willChangeValue(forKey: key)
        if isSelfUser {
            setPrimitiveValue(data, forKey: key)
        } else {
            guard let imageData = data else {
                managedObjectContext?.zm_userImageCache?.removeAllUserImages(self)
                return
            }
            managedObjectContext?.zm_userImageCache?.setUserImage(self, imageData: imageData, size: size)
        }
        didChangeValue(forKey: key)
        managedObjectContext?.saveOrRollback()
    }
    
    public func imageData(for size: ProfileImageSize, queue: DispatchQueue, completion: @escaping (_ imageData: Data?) -> Void) {
        if isSelfUser {
            let imageData = self.imageData(for: size)
            
            queue.async {
                completion(imageData)
            }
        } else {
            managedObjectContext?.zm_userImageCache?.userImage(self, size: size, queue: queue, completion: completion)
        }
    }
    
    @objc(imageDataforSize:)
    public func imageData(for size: ProfileImageSize) -> Data? {
        if isSelfUser {
            willAccessValue(forKey: size.userKeyPath)
            let value = primitiveValue(forKey: size.userKeyPath) as? Data
            didAccessValue(forKey: size.userKeyPath)
            return value
        } else {
            return managedObjectContext?.zm_userImageCache?.userImage(self, size: size)
        }
    }
    
    public static var previewImageDownloadFilter: NSPredicate {
        let assetIdExists = NSPredicate(format: "(%K != nil)", ZMUser.previewProfileAssetIdentifierKey)
        let notCached = NSPredicate() { (user, _) -> Bool in
            guard let user = user as? ZMUser else { return false }
            return user.imageSmallProfileData == nil
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: [assetIdExists, notCached])
    }
    
    public static var completeImageDownloadFilter: NSPredicate {
        let assetIdExists = NSPredicate(format: "(%K != nil)", ZMUser.completeProfileAssetIdentifierKey)
        let notCached = NSPredicate() { (user, _) -> Bool in
            guard let user = user as? ZMUser else { return false }
            return user.imageMediumData == nil
        }
        return NSCompoundPredicate(andPredicateWithSubpredicates: [assetIdExists, notCached])
    }
    
    public func updateAndSyncProfileAssetIdentifiers(previewIdentifier: String, completeIdentifier: String) {
        guard isSelfUser else { return }
        previewProfileAssetIdentifier = previewIdentifier
        completeProfileAssetIdentifier = completeIdentifier
        setLocallyModifiedKeys([ZMUser.previewProfileAssetIdentifierKey, ZMUser.completeProfileAssetIdentifierKey])
    }
    
    @objc public func updateAssetData(with assets: NSArray?, hasLegacyImages: Bool, authoritative: Bool) {
        guard !hasLocalModifications(forKeys: [ZMUser.previewProfileAssetIdentifierKey, ZMUser.completeProfileAssetIdentifierKey]) else { return }
        guard let assets = assets as? [[String : String]], !assets.isEmpty else {
            if authoritative {
                previewProfileAssetIdentifier = nil
                completeProfileAssetIdentifier = nil
                // Deleting image data only if we don't have V2 profile image as well
                if !hasLegacyImages {
                    imageSmallProfileData = nil
                    imageMediumData = nil
                }
            }
            return
        }
        for data in assets {
            if let size = data["size"].flatMap(ProfileImageSize.init), let key = data["key"].flatMap(AssetKey.init) {
                switch size {
                case .preview:
                    if key.stringValue != previewProfileAssetIdentifier {
                        previewProfileAssetIdentifier = key.stringValue
                        imageSmallProfileData = nil
                    }
                case .complete:
                    if key.stringValue != completeProfileAssetIdentifier {
                        completeProfileAssetIdentifier = key.stringValue
                        imageMediumData = nil
                    }
                }
            }
        }
    }
    
    @objc public func requestPreviewProfileImage() {
        guard let moc = self.managedObjectContext, moc.zm_isUserInterfaceContext, !moc.zm_userImageCache.hasUserImage(self, size: .preview) else { return }
        
        localSmallProfileRemoteIdentifier = nil
        moc.enqueueDelayedSave()
        
        NotificationInContext(name: .userDidRequestPreviewAsset,
                              context: moc.notificationContext,
                              object: self.objectID).post()
    }
    
    @objc public func requestCompleteProfileImage() {
        guard let moc = self.managedObjectContext, moc.zm_isUserInterfaceContext, !moc.zm_userImageCache.hasUserImage(self, size: .complete) else { return }
        
        localMediumRemoteIdentifier = nil
        moc.enqueueDelayedSave()
        
        NotificationInContext(name: .userDidRequestCompleteAsset,
                              context: moc.notificationContext,
                              object: self.objectID).post()
    }
}

extension ZMUser {
    @objc(displayNameInConversation:)
    public func displayName(in conversation: ZMConversation?) -> String {
        guard let conversation = conversation, let nameGenerator = self.managedObjectContext?.zm_displayNameGenerator else { return self.displayName }
        return nameGenerator.displayName(for: self, in: conversation)
    }
}

extension NSManagedObject: PrivateStringConvertible {
    public var privateDescription: String {
        let moc: String = self.managedObjectContext?.description ?? "nil"
        
        return "\(type(of: self)) \(Unmanaged.passUnretained(self).toOpaque()): moc=\(moc) objectID=\(self.objectID)"
    }
}
