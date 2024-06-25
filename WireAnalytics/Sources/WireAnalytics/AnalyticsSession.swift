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

import Countly

/// A structure representing a user's profile for analytics purposes.

public struct AnalyticsUserProfile {

    /// The unique identifier for the user's analytics profile.
    public let analyticsIdentifier: String

    /// The team information for the user.
    public let teamInfo: TeamInfo?

    /// The number of contacts the user has.
    public let contactCount: Int?

    public init(
        analyticsIdentifier: String,
        teamInfo: TeamInfo? = nil,
        contactCount: Int? = nil
    ) {
        self.analyticsIdentifier = analyticsIdentifier
        self.teamInfo = teamInfo
        self.contactCount = contactCount
    }
}

/// A struct representing information about the user's team.
public struct TeamInfo {

    /// The identifier for the team the user belongs to.
    public let id: String

    /// The role of the user within the team.
    public let role: String

    /// The size of the team the user belongs to.
    public let size: Int

    public init(id: String, role: String, size: Int) {
        self.id = id
        self.role = role
        self.size = size
    }
}

public struct AnalyticsSession: AnalyticsSessionProtocol {

    private let countly: WireCountly

    public init(
        appKey: String,
        host: URL,
        userProfile: AnalyticsUserProfile
    ) {

        let config = WireCountlyConfig()
        config.appKey = appKey
        config.host = host.absoluteString
        config.deviceID = userProfile.analyticsIdentifier

        self.countly = .init()
        self.countly.start(with: config)
        self.countly.changeDeviceID(withMerge: userProfile.analyticsIdentifier)

        var properties: [String: String] = [
            "user_contacts": userProfile.contactCount.map { String($0.logRound()) } ?? ""
        ]

        if let teamInfo = userProfile.teamInfo {
            properties["team_team_id"] = teamInfo.id
            properties["team_user_type"] = teamInfo.role
            properties["team_team_size"] = String(teamInfo.size)
        }

        for (key, value) in properties {
            WireCountly.user().set(key, value: value)
        }
    }

    public func startSession() {
        self.countly.beginSession()
    }

    public func endSession() {
        countly.endSession()
    }

    public func trackEvent(_ event: AnalyticEvent) {
        countly.recordEvent(event.rawValue)
    }
}
