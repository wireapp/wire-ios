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

import Foundation
import WireDataModel

// sourcery: AutoMockable
/// A local store dedicated to user.
/// The store uses the injected context to perform `CoreData` operations on user objects.
public protocol UserLocalStoreProtocol {

    /// Fetch self user from the local store

    func fetchSelfUser() async -> ZMUser

    /// Fetches a user locally
    ///
    /// - parameters
    ///     - id: The ID of the user.
    ///     - domain: The domain of the user.
    /// - returns : A  local`ZMUser`.

    func fetchUser(
        id: UUID,
        domain: String?
    ) async throws -> ZMUser

    /// Fetches or creates a user locally.
    ///
    /// - parameters:
    ///     - id: The user id to fetch or create locally.
    ///     - domain: The user domain when federated.

    func fetchOrCreateUser(
        id: UUID,
        domain: String?
    ) async -> ZMUser

    /// Fetches or creates users locally.
    ///
    /// - parameters:
    ///     - userIDs: The users id to fetch or create locally.
    /// - returns: A list of users fetched or created locally.

    func fetchOrCreateUsers(
        userIDs: [(id: UUID, domain: String?)]
    ) async -> Set<ZMUser>

    /// Removes user push token from storage.

    func deletePushToken()

    func removeUserFromAllConversations(
        id: UUID,
        domain: String?,
        date: Date
    ) async

    /// Adds a legal hold request to self.
    ///
    /// - parameters:
    ///     - userID: The user ID of the target legalhold subject.
    ///     - clientID: The client ID of the legalhold device.
    ///     - lastPrekey: The last prekey of the legalhold device.
    ///
    /// Legal hold is the ability to provide an auditable transcript of all communication
    /// held by team members that are put under legal hold compliance (from a third-party),
    /// achieved by collecting the content of such communication for later auditing.

    func addSelfLegalHoldRequest(
        userID: UUID,
        clientID: String,
        lastPrekey: WireDataModel.LegalHoldRequest.Prekey
    ) async

    /// Cancels a self user legal hold request.

    func cancelSelfUserLegalholdRequest() async

    /// Update read receipts flags for self user locally.

    func updateSelfUserReadReceipts(
        isReadReceiptsEnabled: Bool,
        isReadReceiptsEnabledChangedRemotely: Bool
    ) async

    /// Persist the supported protocols for the self user.

    func updateSelfUserSupportedProtocols(supportedProtocols: Set<WireDataModel.MessageProtocol>) async

    /// Fetches users qualified IDs locally.
    /// - returns: A list of qualified IDs.

    func fetchUsersQualifiedIDs() async throws -> [WireDataModel.QualifiedID]

    /// Indicates whether the user is a self user.
    /// - Parameters:
    ///     - id: The ID of the user
    ///     - domain: The domain of the user if any.
    /// - returns: The user found locally and a flag indicating if this user is a self user.

    func isSelfUser(
        id: UUID,
        domain: String?
    ) async throws -> (user: ZMUser, isSelfUser: Bool)

    // swiftlint:disable:next todo_requires_jira_link
    // TODO: Should be factored out
    func postAccountDeletedNotification()

    /// Marks a user account as deleted locally.
    /// - parameters:
    ///     - user: The user to mark the account deleted for.

    func markAccountAsDeleted(for user: ZMUser) async

    func updateSelfUserTrackingID(
        trackingID: UUID,
        conversation: ZMConversation
    ) async

    // TODO: [WPB-10727] Merge these two methods into a single method
    func persistUser(userInfo: NewUserInfo) async
    func updateUser(userUpdateInfo: UserUpdateInfo) async

    /// Fetches all user IDs that have a one on one conversation
    /// - returns: A list of users' qualified IDs.

    func fetchAllUserIDsWithOneOnOneConversation() async throws -> [WireDataModel.QualifiedID]

    /// Fetch the self user Supported Protocols

    func fetchSelfUserSupportedProtocols() async -> Set<WireDataModel.MessageProtocol>

    /// Fetches self user info : user ID and client ID.
    /// - returns: the user ID and the client ID.

    func selfUserInfo() async -> (id: UUID, clientId: String?)

    /// The name of a given user.
    /// - Parameter user: The user to fetch the name for.
    /// - returns: The user name.

    func name(
        for user: ZMUser
    ) async -> String?

    /// The team name of a given user.
    /// - Parameter user: The user to fetch the team for.
    /// - returns: The team name if any.

    func teamName(
        for user: ZMUser
    ) async -> String?

    /// The identifier for a given user
    /// - parameter user: The user to get the ID for.
    /// - returns: The user UUID.

    func id(
        for user: ZMUser
    ) async -> UUID

    func fetchSelfUserAvailability() async -> Availability

    func updateUser(with userID: WireDataModel.QualifiedID, availability: Availability) async
}
