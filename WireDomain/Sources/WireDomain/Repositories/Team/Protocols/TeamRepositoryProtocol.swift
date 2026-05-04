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
import WireNetwork

// sourcery: AutoMockable
/// Facilitate access to team related domain objects.
///
/// A repository provides an abstraction for the access and storage
/// of domain models, concealing how and where the models are stored
/// as well as the possible source(s) of the models.
public protocol TeamRepositoryProtocol {

    /// Pull self team metadata from the server and store locally.

    func pullSelfTeam() async throws

    /// Pull team roles for the self team from the server and store locally.

    func pullSelfTeamRoles() async throws

    /// Pull team members for the self team from the server and store locally.

    func pullSelfTeamMembers() async throws

    /// Fetches the legalhold info for the self user from the server.
    /// - returns: The legalhold info.

    func fetchSelfLegalholdInfo() async throws -> TeamMemberLegalholdInfo

    /// Creates or updates a team locally.
    /// - Parameters
    ///     - identifier: The team ID.
    ///     - name: The team name.
    ///     - creator: The team creator.
    ///     - icon: The team icon.
    ///     - iconKey: The team iconKey.

    func createOrUpdateTeam(
        identifier: UUID,
        name: String,
        creator: UUID,
        icon: String,
        iconKey: String?
    ) async

    /// Deletes the member of a team.
    /// - Parameter userID: The ID of the team member.
    /// - Parameter domain: The domain of the team member.
    /// - Parameter date: The time the member left the team.

    func deleteMembership(
        userID: UUID,
        domain: String?,
        date: Date
    ) async throws

    /// Sets the team member `needsToBeUpdatedFromBackend` flag to true.
    /// - Parameter membershipID: The id of the team member.

    func storeTeamMemberNeedsBackendUpdate(
        membershipID: UUID
    ) async throws

    /// Pulls and stores legalhold info locally.

    func pullSelfLegalholdInfo() async throws

}
