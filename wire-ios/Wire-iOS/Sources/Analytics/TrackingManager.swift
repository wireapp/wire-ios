//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import AppCenter
import WireCommonComponents
import avs
import WireSyncEngine

final class TrackingManager: NSObject, TrackingInterface {
    private let flowManagerObserver: NSObjectProtocol

    private override init() {
        AVSFlowManager.getInstance()?.setEnableMetrics(!ExtensionSettings.shared.disableAnalyticsSharing)

        flowManagerObserver = NotificationCenter.default.addObserver(forName: FlowManager.AVSFlowManagerCreatedNotification, object: nil, queue: OperationQueue.main, using: { _ in
            AVSFlowManager.getInstance()?.setEnableMetrics(!ExtensionSettings.shared.disableAnalyticsSharing)
        })
    }

    static let shared = TrackingManager()

    var disableCrashSharing: Bool {
        get {
            return ExtensionSettings.shared.disableCrashSharing
        }

        set {
            updateAppCenterStateIfNeeded(oldState: disableCrashSharing, newValue)
            ExtensionSettings.shared.disableCrashSharing = newValue
        }
    }

    var disableAnalyticsSharing: Bool {
        get {
            return ExtensionSettings.shared.disableAnalyticsSharing
        }

        set {
            Analytics.shared?.isOptedOut = newValue
            AVSFlowManager.getInstance()?.setEnableMetrics(!newValue)
            ExtensionSettings.shared.disableAnalyticsSharing = newValue
        }
    }

    private func updateAppCenterStateIfNeeded(oldState: Bool, _ newState: Bool) {
        switch (oldState, newState) {
        case (true, false):
            AppCenter.enabled = true
            AppCenter.start()
        case (false, true):
            AppCenter.enabled = false
        default:
            return
        }
    }
}


final class TimerActionsManager: NSObject {

    struct Event {
        let interval: TimeInterval
        let condition: Bool
        let action: (() -> Void)
    }

    //static let shared = TimeActionsManager()

    private var events: [Event] = []
    weak var managedObjectContext: NSManagedObjectContext?
    private var lastCheckDate: Date? {
        didSet {
            managedObjectContext?.lastDataRefreshDate = lastCheckDate
        }
    }

    public init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext

        super.init()

        self.lastCheckDate = managedObjectContext.lastDataRefreshDate
        self.events = makeEventsList()
    }

    public func applyTimerActionsIfNeeded(_ checkTime: Date) {
        guard let lastCheckTime = lastCheckDate else {
            return
        }
        events.forEach { event in
            if (lastCheckTime + event.interval) >= checkTime {
                print("More time")
                if event.condition {
                    event.action()
                }
            } else {
                print("Less time")
            }
        }
        setLastCheckTime(checkTime)

    }

    private func setLastCheckTime(_ timestamp: Date?) {
        self.lastCheckDate = timestamp
    }

    private func makeEventsList() -> [Event] {
        /// 1. Create condition
        /// 2. Create action

        let refreshUsersWithMissingMetadata = Event(interval: 30, condition: true, action: {})
        let refreshConversationsWithMissingMetadata = Event(interval: 30, condition: true, action: {})
        return [refreshUsersWithMissingMetadata, refreshConversationsWithMissingMetadata, refreshUsersWithMissingMetadata1()].compactMap { $0 }
    }
}

extension TimerActionsManager {
    private func refreshUsersWithMissingMetadata1() -> Event? {
        ZMUser.sortedFetchRequest()
        return nil
    }
}

extension NSManagedObjectContext {

    private static let LastDataRefreshDateKey = "LastDataRefreshDateKey"

    /// ??
    @objc
    var lastDataRefreshDate: Date? {

        get {
            precondition(zm_isSyncContext, "lastDataRefreshDate can only be accessed on the sync context")
            return userInfo[NSManagedObjectContext.LastDataRefreshDateKey] as? Date
        }

        set {
            precondition(zm_isSyncContext, "lastDataRefreshDate can only be accessed on the sync context")
            userInfo[NSManagedObjectContext.LastDataRefreshDateKey] = newValue
        }

    }

}
