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

// sourcery: AutoMockable
public protocol QuickSyncObserverInterface {
    func waitForQuickSyncToFinish() async
}

public class QuickSyncObserver: QuickSyncObserverInterface {

    let context: NSManagedObjectContext
    let applicationStatus: ApplicationStatus
    let notificationContext: NotificationContext

    public init(context: NSManagedObjectContext, applicationStatus: ApplicationStatus, notificationContext: NotificationContext) {
        self.context = context
        self.applicationStatus = applicationStatus
        self.notificationContext = notificationContext
    }

    public func waitForQuickSyncToFinish() async {
        func quickSyncHasCompleted() async -> Bool {
            await context.perform {
                return self.applicationStatus.synchronizationState == .online
            }
        }

        if await quickSyncHasCompleted() {
            return
        }

        WireLogger.messaging.debug("Waiting for app to be online before sending message")
        for await _ in NotificationCenter.default.notifications(
            named: .quickSyncCompletedNotification,
            object: notificationContext
        ) {
            break
        }
    }
}
