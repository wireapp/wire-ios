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

@objc
public protocol UserConnectionType: NSObjectProtocol {
 
    var isPendingApprovalByOtherUser: Bool { get }
    
}

@objc
public protocol UserType: NSObjectProtocol {
    
    /// The full name
    var name: String? { get }
    
    /// The given name / first name e.g. "John" for "John Smith"
    var displayName: String { get }
    
    /// The "@name" handle
    var handle: String? { get }
    
    /// The initials e.g. "JS" for "John Smith"
    var initials: String? { get }
    
    /// Whether this is the self user
    var isSelfUser: Bool { get }
    
    /// The availability of the user
    var availability: Availability { get set }
    
    /// The name of the team the user belongs to.
    var teamName: String? { get }
    
    /// Whether this is the member of a team
    var isTeamMember: Bool { get }

    /// The role (and permissions) e.g. partner, member, admin, owner
    var teamRole: TeamRole { get }
    
    /// Whether this is a service user (bot)
    var isServiceUser: Bool { get }
    
    /// Is YES if we can send a connection request to this user.
    var isConnected: Bool { get }

    /// Whether the user is blocked.
    var isBlocked: Bool { get }

    /// Whether the user is expired.
    var isExpired: Bool { get }

    /// Whether the user is pending connection approval from the self user.
    var isPendingApprovalBySelfUser: Bool { get }

    /// Whether the user is pending connection approval from another user.
    var isPendingApprovalByOtherUser: Bool { get }

    /// Whether the user can be connected by the self user.
    var canBeConnected: Bool { get }
    
    /// Wheater the account of the user is deleted
    var isAccountDeleted: Bool { get }
    
    var accentColorValue: ZMAccentColor { get }

    /// Whether the user is a wireless user.
    var isWirelessUser: Bool { get }
    
    /// The time remaining before the user expires.
    var expiresAfter: TimeInterval { get }
    
    /// Message text if there's a pending connection request
    var connectionRequestMessage: String? { get }
    
    var smallProfileImageCacheKey: String? { get }
    var mediumProfileImageCacheKey: String? { get }
    
    var previewImageData: Data? { get }
    var completeImageData: Data? { get }
    
    /// Whether read receipts are enabled for this user.
    var readReceiptsEnabled: Bool { get }
    
    /// The extended metadata for this user, provided by SCIM.
    var richProfile: [UserRichProfileField] { get }
    
    /// Used to trigger rich profile download from backend
    var needsRichProfileUpdate: Bool { get set }
    
    /// Conversations the user is a currently a participant of
    var activeConversations: Set<ZMConversation> { get }
    
    func requestPreviewProfileImage()
    func requestCompleteProfileImage()
    
    /// Whether this user is a guest in a conversation
    func isGuest(in conversation: ZMConversation) -> Bool
    
    /// Fetch a profile image with the given size on the given queue
    func imageData(for size: ProfileImageSize, queue: DispatchQueue, completion: @escaping (_ imageData: Data?) -> Void)
    
    /// Request a refresh of the user data from the backend.
    /// This is useful for non-connected user, that we will otherwise never re-fetch
    func refreshData()
    
    /// Sends a connection request to the given user. May be a no-op, eg. if we're already connected.
    /// A ZMUserChangeNotification with the searchUser as object will be sent notifiying about the connection status change
    /// You should stop from observing the searchUser and start observing the user from there on
    func connect(message: String)
    
    /// Determines whether the user profile is managed by Wire or other services (SCIM)
    var managedByWire: Bool { get }

    /// Whether the user can create conversations.
    var canCreateConversation: Bool { get }

    /// Whether the user can access the private company information of the other given user.
    func canAccessCompanyInformation(of user: UserType) -> Bool

    /// Whether the user can add another user to the conversation.
    @objc(canAddUserToConversation:)
    func canAddUser(to conversation: ZMConversation) -> Bool

    /// Whether the user can remove another user from the conversation.
    @objc(canRemoveUserFromConversation:)
    func canRemoveUser(from conversation: ZMConversation) -> Bool

}
