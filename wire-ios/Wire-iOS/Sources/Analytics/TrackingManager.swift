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

import avs
import Foundation
import WireCommonComponents
import WireSyncEngine

final class TrackingManager: NSObject, TrackingInterface {
    private let flowManagerObserver: NSObjectProtocol

    override private init() {
        AVSFlowManager.getInstance()?.setEnableMetrics(!ExtensionSettings.shared.disableAnalyticsSharing)

        self.flowManagerObserver = NotificationCenter.default.addObserver(
            forName: FlowManager.AVSFlowManagerCreatedNotification,
            object: nil,
            queue: OperationQueue.main,
            using: { _ in
                AVSFlowManager.getInstance()?.setEnableMetrics(!ExtensionSettings.shared.disableAnalyticsSharing)
            }
        )
    }

    static let shared = TrackingManager()

    var disableAnalyticsSharing: Bool {
        get { ExtensionSettings.shared.disableAnalyticsSharing }
        set {
            Analytics.shared?.isOptedOut = newValue
            AVSFlowManager.getInstance()?.setEnableMetrics(!newValue)
            ExtensionSettings.shared.disableAnalyticsSharing = newValue
        }
    }
}
