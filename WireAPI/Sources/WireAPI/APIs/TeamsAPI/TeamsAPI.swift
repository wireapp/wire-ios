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

// sourcery: AutoMockable
/// An API access object for endpoints concerning teams.
public protocol TeamsAPI {

    /// Get the team metadata for a specific team.
    ///
    /// - Parameter teamID: The id of the team.
    /// - Returns: The request team metadata.

    func getTeam(for teamID: Team.ID) async throws -> Team

    /// Get the conversation roles for a specific team.
    ///
    /// - Parameter teamID: The id of the team.
    /// - Returns: The conversation roles defined in the team.

    func getTeamRoles(for teamID: Team.ID) async throws -> [ConversationRole]

    /// Get members of a specific team.
    ///
    /// Note this may not return all members of the team.
    ///
    /// - Parameters:
    ///   - teamID: The id of the team.
    ///   - maxResults: The maximum number of members to retrieve.
    ///
    /// - Returns: A list of members.

    func getTeamMembers(
        for teamID: Team.ID,
        maxResults: UInt
    ) async throws -> [TeamMember]

    /// Get the legalhold of a team member.
    ///
    /// - Parameters:
    ///   - teamID: The id of the team.
    ///   - userID: The id of the member.
    /// - Returns: The legalhold of the member.

    func getLegalhold(
        for teamID: Team.ID,
        userID: UUID
    ) async throws -> TeamMemberLegalHold

}
