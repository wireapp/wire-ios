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

import Foundation

// MARK: - QuickSyncObserverInterface

// sourcery: AutoMockable
public protocol QuickSyncObserverInterface {
    func waitForQuickSyncToFinish() async
}

// MARK: - QuickSyncObserver

public final class QuickSyncObserver: QuickSyncObserverInterface {
    // MARK: Lifecycle

    public init(
        context: NSManagedObjectContext,
        applicationStatus: ApplicationStatus,
        notificationContext: NotificationContext
    ) {
        self.context = context
        self.applicationStatus = applicationStatus
        self.notificationContext = notificationContext
    }

    // MARK: Public

    public func waitForQuickSyncToFinish() async {
        if await quickSyncHasCompleted() {
            WireLogger.messaging.info(
                "no need to wait, because quick sync has completed",
                attributes: .safePublic
            )
            return
        }

        WireLogger.messaging.info(
            "Waiting for app to be online before sending message",
            attributes: .safePublic
        )

        for await _ in notificationCenter.notifications(
            named: .quickSyncCompletedNotification,
            object: notificationContext
        ) {
            WireLogger.messaging.info(
                "Quick sync finished",
                attributes: .safePublic
            )
            break
        }
    }

    // MARK: Private

    private let context: NSManagedObjectContext
    private let applicationStatus: ApplicationStatus
    private let notificationCenter: NotificationCenter = .default
    private let notificationContext: NotificationContext

    private func quickSyncHasCompleted() async -> Bool {
        await context.perform {
            self.applicationStatus.synchronizationState == .online
        }
    }
}
