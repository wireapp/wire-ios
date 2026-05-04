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

import Foundation
import WireTransport

private let zmsLog = ZMSLog(tag: "backend-environment")

public extension BackendEnvironment {
    static let backendSwitchNotification = Notification.Name("backendEnvironmentSwitchNotification")
    static var shared: BackendEnvironment = {
        let environmentType = if let typeOverride = AutomationHelper.sharedHelper.backendEnvironmentTypeOverride() {
            EnvironmentType(stringValue: typeOverride)
        } else {
            // read from userDefaults first
            EnvironmentType(userDefaults: .applicationGroup)
        }

        guard let environment = BackendEnvironment(type: environmentType) else {
            fatalError("Malformed backend configuration data")
        }
        return environment
    }() {
        didSet {
            AutomationHelper.sharedHelper.disableBackendTypeOverride()
            shared.save(in: .applicationGroup)
            NotificationCenter.default.post(name: backendSwitchNotification, object: shared)
            zmsLog.debug("Shared backend environment did change to: \(shared.title)")
        }
    }

    convenience init?(type: EnvironmentType?) {
        self.init(
            userDefaults: .applicationGroupCombinedWithStandard,
            configurationBundle: .backendBundle,
            environmentType: type
        )
    }

}
