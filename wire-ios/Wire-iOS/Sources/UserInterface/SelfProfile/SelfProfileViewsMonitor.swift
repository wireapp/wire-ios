//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import WireFoundation
import WireLogging
import WireSyncEngine

protocol SelfProfileViewsMonitor {
    var didViewSelfProfile: Bool { get }

    func onDidViewSelfProfile()
}

class SelfProfileViewsMonitorImplementation: SelfProfileViewsMonitor {
    private enum UserDefaultsKey: String, DefaultsKey {
        case didViewSelfProfile
    }

    private var userSession: UserSession? {
        SessionManager.shared?.activeUserSession
    }

    init() {}

    var didViewSelfProfile: Bool {
        get {
            guard let userSession else {
                // TODO: [WPB-15038] inject to viewController and replace by mock in WireiOS tests
                WireLogger.individualToTeamMigration.warn("no userSession available")
                return false
            }
            let userDefaults = PrivateUserDefaults<UserDefaultsKey>(userID: userSession.selfUser.remoteIdentifier)
            let value = userDefaults.object(forKey: .didViewSelfProfile)

            if value == nil {
                userDefaults.set(false, forKey: .didViewSelfProfile)
            }

            return (value as? Bool) ?? false
        }

        set {
            guard let userSession else {
                // TODO: [WPB-15038] inject to viewController and replace by mock in WireiOS tests
                WireLogger.individualToTeamMigration.warn("no userSession available")
                return
            }
            let userDefaults = PrivateUserDefaults<UserDefaultsKey>(userID: userSession.selfUser.remoteIdentifier)
            userDefaults.set(newValue, forKey: .didViewSelfProfile)
        }
    }

    func onDidViewSelfProfile() {
        didViewSelfProfile = true
        NotificationCenter.default.post(name: .userDidViewSelfProfile, object: nil)
    }
}
