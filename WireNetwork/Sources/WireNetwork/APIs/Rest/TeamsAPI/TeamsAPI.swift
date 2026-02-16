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

public import Foundation

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

    /// Get members of a specific team with the specified ids.
    ///
    /// Note: non-existent ids will be ignored.
    ///
    /// - Parameters:
    ///   - teamID: The id of the team.
    ///   - userIDs: A list of user ids to match team members.
    ///
    /// - Returns: A list of members.

    func getTeamMembers(
        of teamID: Team.ID,
        for userIDs: [UUID]
    ) async throws -> [TeamMember]

    /// Get the legalhold of a team member.
    ///
    /// - Parameters:
    ///   - teamID: The id of the team.
    ///   - userID: The id of the member.
    /// - Returns: The legalhold of the member.

    func getLegalholdInfo(
        for teamID: Team.ID,
        userID: UUID
    ) async throws -> TeamMemberLegalholdInfo

    /// Invite a member to team
    /// - Parameters:
    ///   - teamID: The id of the team.
    ///   - email: team owner email
    ///   - password: team owner password
    ///   - memberName: member's  name
    ///   - memberEmail: member's password
    /// - Returns: invitation-id
    #if DEBUG
        func inviteMemberToTeam(
            access_token: String,
            teamID: UUID,
            memberName: String,
            memberEmail: String
        ) async throws -> UUID
    #endif

    /// Fetches details of an app by team id and app id.

    func getApp(
        for teamID: Team.ID,
        with id: UUID
    ) async throws -> App

    func getWhitelistedBots(
        for teamID: Team.ID,
        with prefix: String
    ) throws -> PayloadPager<[WhitelistedBotProfile]>

}
