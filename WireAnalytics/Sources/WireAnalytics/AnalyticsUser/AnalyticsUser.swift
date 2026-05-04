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

/// The subject of analytics tracking.

public struct AnalyticsUser: Equatable, Sendable {

    /// A unique id.

    public let trackingID: UUID

    /// The user's team information.

    public let teamInfo: TeamInfo?

    /// Create a new `AnalyticsUser`.
    ///
    /// - Parameters:
    ///   - trackingID: A uniqe id.
    ///   - teamInfo: The user's team information.

    public init(
        trackingID: UUID,
        teamInfo: TeamInfo? = nil
    ) {
        self.trackingID = trackingID
        self.teamInfo = teamInfo
    }

}
