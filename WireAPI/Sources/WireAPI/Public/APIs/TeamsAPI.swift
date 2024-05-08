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

}

extension TeamsAPI {
    
    /// Make a new `TeamsAPI` client.
    ///
    /// - Parameters:
    ///   - version: The api version to use.
    ///   - httpClient: A http client.
    ///
    /// - Returns: A versioned implementation of `TeamsAPI`.

    public static func makeAPI(
        for version: APIVersion,
        httpClient: any HTTPClient
    ) -> any TeamsAPI {
        switch version {
        case .v0:
            TeamsAPIV0(httpClient: httpClient)
        case .v1:
            TeamsAPIV1(httpClient: httpClient)
        case .v2:
            TeamsAPIV2(httpClient: httpClient)
        case .v3:
            TeamsAPIV3(httpClient: httpClient)
        case .v4:
            TeamsAPIV4(httpClient: httpClient)
        case .v5:
            TeamsAPIV5(httpClient: httpClient)
        case .v6:
            TeamsAPIV6(httpClient: httpClient)
        }
    }

}
