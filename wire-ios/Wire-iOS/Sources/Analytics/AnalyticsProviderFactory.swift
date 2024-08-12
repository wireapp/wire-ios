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

import WireCommonComponents
import WireSyncEngine

private let zmLog = ZMSLog(tag: "Analytics")

final class AnalyticsProviderFactory: NSObject {
    static let shared = AnalyticsProviderFactory(userDefaults: .shared()!)

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    func analyticsProvider() -> AnalyticsProvider? {
        if AutomationHelper.sharedHelper.useAnalytics {
            // Create & return valid provider, when available.
            guard
                let appKey = Bundle.countlyAppKey,
                let url = BackendEnvironment.shared.countlyURL
            else {
                zmLog.error("Could not create Countly provider. Make sure COUNTLY_APP_KEY in .xcconfig is set and countlyURL exists in backend environment.")
                return nil
            }

            return AnalyticsCountlyProvider(countlyAppKey: appKey, serverURL: url)

        } else {
            zmLog.info("Creating analyticsProvider: no provider")
            return nil
        }
    }
}
