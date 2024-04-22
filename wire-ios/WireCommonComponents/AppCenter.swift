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

import AppCenter
import AppCenterCrashes
import AppCenterDistribute
import AppCenterAnalytics

extension AppCenter {
    public static func setTrackingEnabled(_ enabled: Bool) {
        Analytics.enabled = enabled
        Distribute.enabled = enabled
#if DISABLE_APPCENTER_CRASH_LOGGING
        Crashes.enabled = false
#else
        Crashes.enabled = enabled
#endif
    }
    public static func start() {
        Distribute.updateTrack = .private

#if DISABLE_APPCENTER_CRASH_LOGGING
        let services = [Distribute.self,
                        Analytics.self]
#else
        let services = [Crashes.self,
                        Distribute.self,
                        Analytics.self]
#endif
        AppCenter.start(withAppSecret: Bundle.appCenterAppId, services: services)
    }
}
