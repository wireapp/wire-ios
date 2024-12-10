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

/// An enumeration representing the keys used for user analytics data.
/// This enum provides type-safe access to the keys used for setting user values in the analytics service.
enum AnalyticsUserKey: String, CaseIterable {

    /// The key for the team ID.
    case teamID = "team_team_id"

    /// The key for the user type within the team.
    case teamRole = "team_user_type"

    /// The key for the size of the team.
    case teamSize = "team_team_size"
}
