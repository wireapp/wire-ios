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
import WireNetwork

// sourcery: AutoMockable
/// Facilitate access to users related domain objects.
///
/// A repository provides an abstraction for the access and storage
/// of domain models, concealing how and where the models are stored
/// as well as the possible source(s) of the models.
public protocol UserRepositoryProtocol {

    /// Pulls self user and stores it locally

    func pullSelfUser() async throws

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

    /// Fetch and persist all locally known users

    func pullKnownUsers() async throws

    /// Fetch and persist a list of users
    ///
    /// - parameters:
    ///     - userIDs: IDs of users to fetch

    func pullUsers(userIDs: [WireDataModel.QualifiedID]) async throws

    /// Updates a user.
    ///
    /// - parameters:
    ///     - event: The event to update the user locally from.

    func updateUser(
        from event: UserUpdateEvent
    ) async

    /// Fetches or creates a user locally.
    ///
    /// - parameters:
    ///     - id: The user id to fetch or create locally.
    ///     - domain: The user domain when federated.

    func fetchOrCreateUser(
        id: UUID,
        domain: String?
    ) async -> ZMUser

    /// Removes user push token from storage.

    func removePushToken()

    /// Adds a legal hold request.
    ///
    /// - parameters:
    ///     - userID: The user ID of the target legalhold subject.
    ///     - clientID: The client ID of the legalhold device.
    ///     - lastPrekey: The last prekey of the legalhold device.
    ///
    /// Legal hold is the ability to provide an auditable transcript of all communication
    /// held by team members that are put under legal hold compliance (from a third-party),
    /// achieved by collecting the content of such communication for later auditing.

    func addLegalHoldRequest(
        userID: UUID,
        clientID: String,
        lastPrekey: Prekey
    ) async

    /// Disables user legal hold.

    func disableUserLegalHold() async

    /// Updates a user property
    ///
    /// - parameters:
    ///     - userProperty: The user property to update.

    func updateUserProperty(
        _ userProperty: WireNetwork.UserProperty
    ) async throws

    /// Deletes a user property.
    ///
    /// - parameters:
    ///     - key: The user property key to delete.

    func deleteUserProperty(
        withKey key: UserProperty.Key
    ) async

    /// Deletes the user account.
    ///
    /// - parameters:
    ///     - user: The user to delete the account for.
    ///     - date: The date the user was deleted.

    func deleteUserAccount(
        id: UUID,
        domain: String?,
        at date: Date
    ) async throws

    /// Indicates whether a given user is a self user.
    /// - Parameters:
    ///     - id: The user id.
    ///     - domain: The user domain if any.
    /// - Returns: Whether the user is self user.

    func isSelfUser(
        id: UUID,
        domain: String?
    ) async throws -> Bool

    /// Fetches all user IDs that have a one on one conversation
    /// - returns: A list of users' qualified IDs.

    func fetchAllUserIDsWithOneOnOneConversation() async throws -> [WireDataModel.QualifiedID]

}
