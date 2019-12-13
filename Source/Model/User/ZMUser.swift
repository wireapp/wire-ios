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
    
    public var teamName: String? {
        return team?.name
    }
    
    public var previewImageData: Data? {
        return imageSmallProfileData
    }
    
    public var completeImageData: Data? {
        return imageMediumData
    }
    
    public var activeConversations: Set<ZMConversation> {
        return Set(self.participantRoles.filter{!$0.markedForDeletion}.map{$0.conversation})
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
    
    @objc static let previewProfileAssetIdentifierKey = #keyPath(ZMUser.previewProfileAssetIdentifier)
    @objc static let completeProfileAssetIdentifierKey = #keyPath(ZMUser.completeProfileAssetIdentifier)
    
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
    
    @NSManaged var expiresAt: Date?
    
    /// `accountIsDeleted` is true if this account has been deleted on the backend
    @NSManaged public internal(set) var isAccountDeleted: Bool
    
    @NSManaged public var usesCompanyLogin: Bool
    
    /// If `needsToRefetchLabels` is true we need to refetch the conversation labels (favorites & folders)
    @NSManaged public var needsToRefetchLabels: Bool
    
    
    /// Conversation in which the user is active, according to the server
    public var lastServerSyncedActiveConversations: Set<ZMConversation> {
        get {
            ///TODO: review
            return Set(participantRoles.compactMap {
                if !$0.markedForDeletion {
                    return $0.conversation
                } else {
                    return nil
                }
            })
        }
        
        set {
            participantRoles = Set()
            union(conversationSet: newValue)
        }
    }
    
    @objc
    func add(conversation: ZMConversation) {
        guard let moc = self.managedObjectContext else { return }
        
        ParticipantRole.create(managedObjectContext: moc, user: self, conversation: conversation)
    }
    
    /// union a ZMConversation set to participantRoles
    ///
    /// - Parameter conversationSet: conversations to union
    @objc
    func union(conversationSet: Set<ZMConversation>) {
        let currentConversationSet = lastServerSyncedActiveConversations
        
        conversationSet.forEach() { conversation in
            if !currentConversationSet.contains(conversation) {
                add(conversation: conversation)
            } else if currentConversationSet.contains(conversation) {
                ///if mark for delete, set markedForDeletion to false
                participantRoles.first(where: {$0.markedForDeletion})?.operationToSync = .none
            }
        }
    }
    
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
        let allGroupConversations: [ZMConversation] = lastServerSyncedActiveConversations.compactMap {
            guard $0.conversationType == .group else { return nil}
            return $0
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
    @objc(displayNameInConversation:)
    public func displayName(in conversation: ZMConversation?) -> String {
        guard let conversation = conversation, let nameGenerator = self.managedObjectContext?.zm_displayNameGenerator else { return self.displayName }
        return nameGenerator.displayName(for: self, in: conversation)
    }
    
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
