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

/// A structure representing a user's profile for analytics purposes.
public struct AnalyticsUserProfile {

    /// The unique identifier for the user's analytics profile.
    public let analyticsIdentifier: String

    /// The team information for the user.
    public let teamInfo: TeamInfo?

    public init(
        analyticsIdentifier: String,
        teamInfo: TeamInfo? = nil
    ) {
        self.analyticsIdentifier = analyticsIdentifier
        self.teamInfo = teamInfo
    }
}
