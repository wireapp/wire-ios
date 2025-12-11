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

import Foundation
import WireLogging

public extension ZMUserSession {

    func application(
        _ application: ZMApplication,
        didFinishLaunching launchOptions: [UIApplication.LaunchOptionsKey: Any?]
    ) {
        startEphemeralTimers()
    }

    func application(
        _ application: ZMApplication,
        performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // TODO: [WPB-17583] re-enable background fetch for new sync.
        guard !journal[.isSyncV2Enabled] else {
            WireLogger.sync.debug("background fetch is triggered")
            Task {
                WireLogger.sync.debug("Sync already running: \(syncAgent?.syncRunning ?? false)")
                await self.syncAgent?.suspend()
                WireLogger.sync.debug("Sync suspended")
                completionHandler(.noData)
            }
            // disable background fetch
            application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalNever)
            return
        }

        BackgroundActivityFactory.shared.resume()

        syncManagedObjectContext.performGroupedBlock {
            self.applicationStatusDirectory.operationStatus
                .startBackgroundFetch(withCompletionHandler: completionHandler)
        }
    }

    func application(
        _ application: ZMApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }

    @objc
    func applicationDidEnterBackground(_ note: Notification?) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let hasActiveCalls = self.callCenter?.activeCalls.isEmpty == false

            if !hasActiveCalls {
                await self.syncAgent?.suspend()
            }
        }

        stopEphemeralTimers()
        lockDatabase()
        recalculateUnreadMessages()

        do {
            try purgeTemporaryAssets()
        } catch {
            WireLogger.assets.error("failed to purge temporary assets: \(error)")
        }
    }

    @objc
    func applicationWillEnterForeground(_ note: Notification?) {
        syncAgent?.resume()
        mergeChangesFromStoredSaveNotificationsIfNeeded()
        startEphemeralTimers()
        deleteOldEphemeralMessages()
        processPendingEvents()
    }

    internal func processPendingEvents() {
        guard !journal[.isSyncV2Enabled] else { return }
        syncContext.performGroupedBlock {
            self.processLegacyEvents()
        }
    }

    internal func deleteOldEphemeralMessages() {
        // In the case that an ephemeral was sent via the share extension, we need
        // to ensure that they have timers running or are deleted/obfuscated if
        // needed. Note: ZMMessageTimer will only create a new timer for a message
        // if one does not already exist.
        syncManagedObjectContext.performGroupedBlock {
            ZMMessage.deleteOldEphemeralMessages(self.syncManagedObjectContext)
        }
    }

    internal func mergeChangesFromStoredSaveNotificationsIfNeeded() {
        let storedNotifications = storedDidSaveNotifications.storedNotifications
        storedDidSaveNotifications.clear()

        guard !storedNotifications.isEmpty else { return }

        for changes in storedNotifications {
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [managedObjectContext])

            syncManagedObjectContext.performGroupedBlock {
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: changes,
                    into: [self.syncManagedObjectContext]
                )
            }
        }

        // we only process pending changes on sync context bc changes on the
        // ui context will be processed when we do the save.
        syncManagedObjectContext.performGroupedBlock {
            self.syncManagedObjectContext.processPendingChanges()
        }

        managedObjectContext.saveOrRollback()
    }

    internal func recalculateUnreadMessages() {
        WireLogger.badgeCount.info("recalculate unread conversations")
        syncManagedObjectContext.performGroupedBlock {
            ZMConversation.recalculateUnreadMessages(in: self.syncManagedObjectContext)
            self.syncManagedObjectContext.saveOrRollback()
            NotificationInContext(name: .calculateBadgeCount, context: self.notificationContext).post()
        }
    }

}
