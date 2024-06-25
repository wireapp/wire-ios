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

    /// The identifier for the team the user belongs to.
    public let teamID: String?

    /// The role of the user within the team.
    public let teamRole: String

    /// The size of the team the user belongs to.
    public let teamSize: Int?

    /// The number of contacts the user has.
    public let contactCount: Int?

    public init(
        analyticsIdentifier: String,
        teamID: String? = nil,
        teamRole: String,
        teamSize: Int? = nil,
        contactCount: Int? = nil
    ) {

        self.analyticsIdentifier = analyticsIdentifier
        self.teamID = teamID
        self.teamRole = teamRole
        self.teamSize = teamSize
        self.contactCount = contactCount

    }

}

public struct AnalyticsSession: AnalyticsSessionProtocol {

    let countly: WireCountly
    let appKey: String
    let host: URL
    private var userProfile: AnalyticsUserProfile?

    public init(
        appKey: String,
        host: URL,
        userProfile: AnalyticsUserProfile
    ) {
        self.appKey = appKey
        self.host = host
        self.userProfile = userProfile

        let config = WireCountlyConfig()
        config.appKey = appKey
        config.host = host.absoluteString
        config.deviceID = userProfile.analyticsIdentifier

        self.countly = .init()
        self.countly.start(with: config)
        self.countly.changeDeviceID(withMerge: userProfile.analyticsIdentifier)

        let properties: [String: String] = [
            "team_team_id": userProfile.teamID ?? "",
            "team_user_type": userProfile.teamRole,
            "team_team_size": userProfile.teamSize.map { String($0) } ?? "",
            "user_contacts": userProfile.contactCount.map { String($0.logRound()) } ?? ""
        ]

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

// Extension to logRound
extension Int {
    func logRound() -> Int {
        return Int(log2(Double(self)).rounded())
    }
}
