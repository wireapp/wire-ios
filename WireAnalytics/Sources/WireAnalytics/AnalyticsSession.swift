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

public struct AnalyticsSession: AnalyticsSessionProtocol {

    private let countly: WireCountly

    private let osVersion: String = ""
    private let deviceModel: String = ""
    private let isSelfUserTeamMember: Bool

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

        if let teamInfo = userProfile.teamInfo {
            WireCountly.user().set("team_team_id", value: teamInfo.id)
            WireCountly.user().set("team_user_type", value: teamInfo.role)
            WireCountly.user().set("team_team_size", value: String(teamInfo.size.logRound()))
        }

        isSelfUserTeamMember = userProfile.teamInfo != nil

        WireCountly.user().save()
    }

    public func startSession() {
        self.countly.beginSession()
    }

    public func endSession() {
        countly.endSession()
    }

    public func trackEvent(_ event: any AnalyticEvent) {
        let defaultSegmentation = [
            "os_version": osVersion,
            "device_model": deviceModel,
            "is_team_member": String(isSelfUserTeamMember)
        ]

        let segmentation = defaultSegmentation.merging(event.segmentation) { _, new in new }

        countly.recordEvent(
            event.eventName,
            segmentation: segmentation
        )
    }
}
