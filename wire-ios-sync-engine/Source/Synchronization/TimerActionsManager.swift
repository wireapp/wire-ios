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

public final class TimerActionsManager: NSObject, TimerActionsManagerType {

    // MARK: - Models

    struct Event {
        let action: (() -> Void)?
    }

    /// Performing actions every 3 hours.
    private let interval: TimeInterval = 3 * 60 * 60

    weak var managedObjectContext: NSManagedObjectContext?

    // MARK: - Initialization

    public init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext

        super.init()
    }

    public func applyTimerActionsIfNeeded(_ currentCheckTime: Date) {
        managedObjectContext?.performGroupedBlock {
            guard let lastCheckDate = UserDefaults.standard.lastDataRefreshDate else {
                self.setLastCheckTime(currentCheckTime)
                return
            }

            if (lastCheckDate + self.interval) <= currentCheckTime {
                self.makeEventsList().forEach { $0.action?() }
                self.setLastCheckTime(currentCheckTime)
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

        let fetchRequest = ZMUser.sortedFetchRequest(with: ZMUser.predicateForUsersWithIncompleteMetadata())
        guard let users = self.managedObjectContext?.fetchOrAssert(request: fetchRequest) as? [ZMUser] else {
            return Event(action: nil)
        }

        return Event {
            users.forEach { $0.refreshData() }
        }

    }

    private func refreshConversationsWithMissingMetadata() -> Event {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ZMConversation.entityName())
        fetchRequest.predicate = NSPredicate(format: "\(ZMConversationHasIncompleteMetadataKey) == YES")

        let conversations = managedObjectContext?.executeFetchRequestOrAssert(fetchRequest) as? [ZMConversation]

        return Event {
            conversations?.forEach { $0.needsToBeUpdatedFromBackend = true }
        }
    }

}

public extension UserDefaults {

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
