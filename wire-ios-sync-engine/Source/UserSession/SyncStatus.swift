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

private let zmLog = ZMSLog(tag: "SyncStatus")

extension Notification.Name {

    public static let ForceSlowSync = Notification.Name("restartSlowSyncNotificationName")
    static let triggerQuickSync = Notification.Name("triggerQuickSync")

}

@objcMembers public class SyncStatus: NSObject, SyncProgress {

    private static let logger = Logger(subsystem: "VoIP Push", category: "SyncStatus")

    public internal (set) var currentSyncPhase: SyncPhase = .done {
        didSet {
            if currentSyncPhase != oldValue {
                self.log()
                zmLog.debug("did change sync phase: \(currentSyncPhase)")
                notifySyncPhaseDidStart()
            }
        }
    }

    fileprivate var lastUpdateEventID: UUID?
    fileprivate unowned var managedObjectContext: NSManagedObjectContext
    fileprivate unowned var syncStateDelegate: ZMSyncStateDelegate
    fileprivate var forceSlowSyncToken: Any?

    public internal (set) var isFetchingNotificationStream: Bool = false
    public internal (set) var isInBackground: Bool = false
    public internal (set) var needsToRestartQuickSync: Bool = false
    public internal (set) var pushChannelEstablishedDate: Date?

    fileprivate var pushChannelIsOpen: Bool {
        return pushChannelEstablishedDate != nil
    }

    public var isSlowSyncing: Bool {
        return !currentSyncPhase.isOne(of: [.fetchingMissedEvents, .done])
    }

    private var isForceQuickSync = false

    public var isSyncing: Bool {
        // TODO: Improve this solution.
        // When triggering a quick sync in the bg when answering a call,
        // we need to be able to process events. But I'm not certain if this
        // is the best way. I think we're using this computed property to control
        // whether the sync bar in the ui is shown or not. In this case, it makes
        // sense that we only hide the bar if the syncing is complete and push
        // channel is open.
        if isForceQuickSync {
            return currentSyncPhase.isSyncing
        } else {
            return currentSyncPhase.isSyncing || !pushChannelIsOpen
        }
    }

    public init(managedObjectContext: NSManagedObjectContext, syncStateDelegate: ZMSyncStateDelegate) {
        self.managedObjectContext = managedObjectContext
        self.syncStateDelegate = syncStateDelegate
        super.init()

        currentSyncPhase = hasPersistedLastEventID ? .fetchingMissedEvents : .fetchingLastUpdateEventID
        notifySyncPhaseDidStart()

        self.forceSlowSyncToken = NotificationInContext.addObserver(name: .ForceSlowSync, context: managedObjectContext.notificationContext) { [weak self] (_) in
            self?.forceSlowSync()
        }

        NotificationCenter.default.addObserver(
            forName: .triggerQuickSync,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.forceQuickSync()
        }
    }

    fileprivate func notifySyncPhaseDidStart() {
        switch currentSyncPhase {
        case .fetchingMissedEvents:
            syncStateDelegate.didStartQuickSync()
        case .fetchingLastUpdateEventID:
            syncStateDelegate.didStartSlowSync()
        default:
            break
        }
    }

    public func forceSlowSync() {
        // Refetch user settings.
        ZMUser.selfUser(in: managedObjectContext).needsPropertiesUpdate = true
        // Set the status.
        currentSyncPhase = SyncPhase.fetchingLastUpdateEventID.nextPhase
        self.log("slow sync")
        syncStateDelegate.didStartSlowSync()
    }

    public func forceQuickSync() {
        isForceQuickSync = true
        currentSyncPhase = .fetchingMissedEvents
        self.log("quick sync")
        RequestAvailableNotification.notifyNewRequestsAvailable(self)

    }

}

// MARK: Slow Sync
extension SyncStatus {

    public func finishCurrentSyncPhase(phase: SyncPhase) {
        precondition(phase == currentSyncPhase, "Finished syncPhase does not match currentPhase")

        zmLog.debug("finished sync phase: \(phase)")
        log("finished sync phase")

        if phase.isLastSlowSyncPhase {
            persistLastUpdateEventID()
            syncStateDelegate.didFinishSlowSync()
        }

        currentSyncPhase = phase.nextPhase

        if currentSyncPhase == .done {
            if needsToRestartQuickSync && pushChannelIsOpen {
                // If the push channel closed while fetching notifications
                // We need to restart fetching the notification stream since we might be missing notifications
                currentSyncPhase = .fetchingMissedEvents
                needsToRestartQuickSync = false
                zmLog.debug("restarting quick sync since push channel was closed")
                return
            }

            zmLog.debug("sync complete")
            syncStateDelegate.didFinishQuickSync()
            isForceQuickSync = false
        }
        RequestAvailableNotification.notifyNewRequestsAvailable(self)
    }

    public func failCurrentSyncPhase(phase: SyncPhase) {
        precondition(phase == currentSyncPhase, "Failed syncPhase does not match currentPhase")

        zmLog.debug("failed sync phase: \(phase)")

        if currentSyncPhase == .fetchingMissedEvents {
            managedObjectContext.zm_lastNotificationID = nil
            currentSyncPhase = .fetchingLastUpdateEventID
            needsToRestartQuickSync = false
        }
    }

    var hasPersistedLastEventID: Bool {
        return managedObjectContext.zm_lastNotificationID != nil
    }

    public func updateLastUpdateEventID(eventID: UUID) {
        zmLog.debug("update last eventID: \(eventID)")
        lastUpdateEventID = eventID
    }

    public func persistLastUpdateEventID() {
        guard let lastUpdateEventID = lastUpdateEventID else { return }
        zmLog.debug("persist last eventID: \(lastUpdateEventID)")
        managedObjectContext.zm_lastNotificationID = lastUpdateEventID
    }

    public func removeLastUpdateEventID() {
        lastUpdateEventID = nil
        zmLog.debug("remove last eventID")
        managedObjectContext.zm_lastNotificationID = nil
        managedObjectContext.enqueueDelayedSave()
    }
}

// MARK: Quick Sync
extension SyncStatus {

    public func beganFetchingNotificationStream() {
        isFetchingNotificationStream = true
    }

    public func failedFetchingNotificationStream() {
        if currentSyncPhase == .fetchingMissedEvents {
            failCurrentSyncPhase(phase: .fetchingMissedEvents)
        }

        isFetchingNotificationStream = false
    }

    @objc(completedFetchingNotificationStreamFetchBeganAt:)
    public func completedFetchingNotificationStream(fetchBeganAt: Date?) {
        if currentSyncPhase == .fetchingMissedEvents &&
           pushChannelEstablishedDate < fetchBeganAt {

            // Only complete the .fetchingMissedEvents phase if the push channel was
            // established before we initiated the notification stream fetch.
            // If the push channel disconnected in between we'll fetch the stream again
            finishCurrentSyncPhase(phase: .fetchingMissedEvents)
        }

        isFetchingNotificationStream = false
    }

    public func pushChannelDidClose() {
        Self.logger.trace("push channel did close")
        pushChannelEstablishedDate = nil

        if !currentSyncPhase.isSyncing {
            // As soon as the pushChannel closes we should notify the UI that we are syncing (if we are not already syncing)
            self.syncStateDelegate.didStartQuickSync()
        }
    }

    public func pushChannelDidOpen() {
        Self.logger.trace("push channel did open")
        pushChannelEstablishedDate = Date()

        if currentSyncPhase == .fetchingMissedEvents {
            // If the push channel closed while we are fetching the notifications, we might be missing notifications that
            // were sent between the server response and the channel re-opening We therefore need to mark the quick sync to be re-started
            needsToRestartQuickSync = true
        }

        if !currentSyncPhase.isSyncing {
            // When the push channel opens we need to start syncing (if we are not already syncing)
            self.currentSyncPhase = .fetchingMissedEvents
        }
    }

    private func log(_ message: String? = nil) {
        let info = SyncStatusLog(phase: currentSyncPhase.description,
                                 isSyncing: isSyncing,
                                 pushChannelEstablishedDate: pushChannelEstablishedDate?.description,
                                 message: message)
        do {
            let data = try JSONEncoder().encode(info)
            let jsonString = String(data: data, encoding: .utf8)
            let message = "SYNC_STATUS: \(jsonString ?? self.description)"
            RemoteMonitoring.remoteLogger?.log(message: message, error: nil, attributes: nil, level: .debug)
        } catch {
            let message = "SYNC_STATUS: \(self.description)"
            RemoteMonitoring.remoteLogger?.log(message: message, error: nil, attributes: nil, level: .error)
        }
    }
}
