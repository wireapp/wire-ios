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

public struct AnalyticsManager: AnalyticsManagerProtocol {

    private let analyticsService: any AnalyticsService

    public init(
        appKey: String,
        host: URL
    ) {
        self.init(
            appKey: appKey,
            host: host,
            analyticsService: Countly.sharedInstance()
        )
    }

    init(
        appKey: String,
        host: URL,
        analyticsService: any AnalyticsService
    ) {
        self.analyticsService = analyticsService
        self.analyticsService.start(appKey: appKey, host: host)
    }

    public func switchUser(_ userProfile: AnalyticsUserProfile) -> any AnalyticsSessionProtocol {
        analyticsService.endSession()
        analyticsService.changeDeviceID(userProfile.analyticsIdentifier)
        analyticsService.setUserValue(userProfile.teamInfo?.id, forKey: "team_team_id")
        analyticsService.setUserValue(userProfile.teamInfo?.role, forKey: "team_user_type")
        analyticsService.setUserValue(userProfile.teamInfo.map { String($0.size.logRound()) }, forKey: "team_team_size")
        analyticsService.beginSession()
        return analyticsService
    }

}

extension Countly: AnalyticsService {

    func start(appKey: String, host: URL) {
        let config = CountlyConfig()
        config.appKey = appKey
        config.host = host.absoluteString
        start(with: config)
    }

    func changeDeviceID(_ id: String) {
        changeDeviceID(withMerge: id)
    }

    func setUserValue(_ value: Any?, forKey key: String) {
        WireCountly.user().setValue(value, forKey: key)
    }

    public func trackEvent(_ event: AnalyticEvent) {
        recordEvent(event.rawValue)
    }

}
