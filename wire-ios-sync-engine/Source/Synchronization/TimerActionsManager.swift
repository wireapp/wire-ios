//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

@objc
public protocol TimerActionsManagerType: AnyObject {

    func applyTimerActionsIfNeeded(_ checkTime: Date)
}
/// add tests
final class TimerActionsManager: NSObject, TimerActionsManagerType {

    // MARK: - Models

    struct Event {
        let interval: TimeInterval
        let action: (() -> Void)?
    }

    weak var managedObjectContext: NSManagedObjectContext?

    // MARK: - Initialization

    public init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext

        super.init()
    }

    public func applyTimerActionsIfNeeded(_ currentCheckTime: Date) {
        managedObjectContext?.performGroupedBlock {
            defer {
                self.setLastCheckTime(currentCheckTime)
            }

            guard let lastCheckDate = UserDefaults.standard.lastDataRefreshDate else {
                return
            }
            let events = self.makeEventsList()

            events.forEach { event in
                if (lastCheckDate + event.interval) <= currentCheckTime {
                    event.action?()
                }
            }
            self.managedObjectContext?.saveOrRollback()
        }
    }

    private func setLastCheckTime(_ lastCheckDate: Date?) {
        UserDefaults.standard.lastDataRefreshDate = lastCheckDate
    }

    private func makeEventsList() -> [Event] {
        return [refreshUsersWithMissingMetadata(),
                refreshConversationsWithMissingMetadata()]
    }
}

extension TimerActionsManager {

    private func refreshUsersWithMissingMetadata() -> Event {
        /// Refresh users without metadata every 3 hours.
        let refreshInterval: TimeInterval = 20

        let fetchRequest = ZMUser.sortedFetchRequest(with: ZMUser.predicateForUsersWithEmptyName())
        guard let users = self.managedObjectContext?.fetchOrAssert(request: fetchRequest) as? [ZMUser] else {
            return Event(interval: refreshInterval, action: nil)
        }

        return Event(interval: refreshInterval) {
            users.forEach { $0.refreshData() }
        }
    }

    private func refreshConversationsWithMissingMetadata() -> Event {
        /// Refresh conversations without metadata every 3 hours.
        let refreshInterval: TimeInterval = 20

        let fetchRequest = ZMConversation.sortedFetchRequest(with: ZMConversation.predicateForGroupConversationsWithEmptyName())
        guard let conversations = self.managedObjectContext?.fetchOrAssert(request: fetchRequest) as? [ZMConversation] else {
            return Event(interval: refreshInterval, action: nil)
        }

        return Event(interval: refreshInterval) {
            conversations.forEach { convo in
                convo.needsToBeUpdatedFromBackend = true
            }
        }
    }

}

public extension UserDefaults {

    /// check for 2 accounts
    private var lastDataRefreshDateKey: String { "LastDataRefreshDateKey" }

    var lastDataRefreshDate: Date? {

        get {
            return object(forKey: lastDataRefreshDateKey) as? Date
        }

        set {
            set(newValue, forKey: lastDataRefreshDateKey)
        }
    }
}
