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
    
    /// Whether this is the member of a team
    var isTeamMember: Bool { get }

    /// The role (and permissions) e.g. partner, member, admin, owner
    var teamRole: TeamRole { get }
    
    /// Whether this is a service user (bot)
    var isServiceUser: Bool { get }
    
    /// Is YES if we can send a connection request to this user.
    var isConnected: Bool { get }
    
    var accentColorValue: ZMAccentColor { get }
    
    /// Message text if there's a pending connection request
    var connectionRequestMessage: String? { get }
    
    var smallProfileImageCacheKey: String? { get }
    var mediumProfileImageCacheKey: String? { get }
    
    var previewImageData: Data? { get }
    var completeImageData: Data? { get }
    
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
    
}

