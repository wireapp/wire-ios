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

import WireDomain
import WireLogging

private let zmLog = ZMSLog(tag: "SyncStatus")

public extension Notification.Name {

    static let initialSync = Notification.Name("ZMInitialSyncCompletedNotification")
    static let resyncResources = Notification.Name("resyncResourcesNotificationName")

    internal static let triggerQuickSync = Notification.Name("triggerQuickSync")

}

@objcMembers
public class SyncStatus: NSObject, SyncStatusProtocol, SyncProgress {

    private static let logger = Logger(subsystem: "VoIP Push", category: "SyncStatus")

    public internal(set) var currentSyncPhase: SyncPhase = .done {
        didSet {
            if currentSyncPhase != oldValue {
                if currentSyncPhase != .done {
                    logSyncPhaseStarted(phase: currentSyncPhase)
                }
                notifySyncPhaseDidStart()
            }
        }
    }

    weak var syncStateDelegate: ZMSyncStateDelegate?

    private let isSyncV2Enabled: Bool

    private let syncTimeTracker = SyncTimeTracker()

    private let lastEventIDRepository: LastEventIDRepositoryInterface
    fileprivate var lastUpdateEventID: UUID?
    fileprivate unowned var managedObjectContext: NSManagedObjectContext
    fileprivate var resyncResourcesToken: Any?

    public internal(set) var isFetchingNotificationStream: Bool = false
    public internal(set) var isInBackground: Bool = false
    public internal(set) var needsToRestartQuickSync: Bool = false
    public internal(set) var pushChannelEstablishedDate: Date?

    var quickSyncContinuation: CheckedContinuation<Void, Never>?

    public var isLive: Bool {
        guard !isSyncV2Enabled else { return false }
        return managedObjectContext.performAndWait {
            currentSyncPhase == .done && isPushChannelOpen
        }
    }

    public var isSlowSyncing: Bool {
        guard !isSyncV2Enabled else { return false }
        return !currentSyncPhase.isOne(of: [.fetchingMissedEvents, .done])
    }

    private var isForceQuickSync = false
    private var isRecovering = false

    public var isSyncing: Bool {
        guard !isSyncV2Enabled else { return false }
        return currentSyncPhase.isSyncing || !isPushChannelOpen
    }

    public var isSyncingInBackground: Bool {
        guard !isSyncV2Enabled else { return false }
        return currentSyncPhase.isSyncing
    }

    public var isPushChannelOpen: Bool {
        guard !isSyncV2Enabled else { return false }
        return pushChannelEstablishedDate != nil
    }

    public init(
        managedObjectContext: NSManagedObjectContext,
        lastEventIDRepository: LastEventIDRepositoryInterface,
        isSyncV2Enabled: Bool
    ) {
        self.managedObjectContext = managedObjectContext
        self.lastEventIDRepository = lastEventIDRepository
        self.isSyncV2Enabled = isSyncV2Enabled

        super.init()

        self.resyncResourcesToken = NotificationInContext.addObserver(
            name: .resyncResources,
            context: managedObjectContext.notificationContext
        ) { [weak self] _ in
            self?.resyncResources()
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
            logSyncStarted()
            syncStateDelegate?.didStartQuickSync()
        case .fetchingLastUpdateEventID:
            logSyncStarted()
            syncStateDelegate?.didStartSlowSync()
        default:
            break
        }
    }

    public func determineInitialSyncPhase() {
        currentSyncPhase = hasPersistedLastEventID ? .fetchingMissedEvents : .fetchingLastUpdateEventID
        resetSyncTimeTracker()
        notifySyncPhaseDidStart()
    }

    public func forceSlowSync() {
        managedObjectContext.performAndWait { [weak self] in
            guard let self else { return }
            // Refetch user settings.
            ZMUser.selfUser(in: managedObjectContext).needsPropertiesUpdate = true
            resetSyncTimeTracker()
            // Reset the status.
            currentSyncPhase = SyncPhase.fetchingLastUpdateEventID
            RequestAvailableNotification.notifyNewRequestsAvailable(nil)
            logSyncStarted()
            syncStateDelegate?.didStartSlowSync()
        }
    }

    /// Sync the resources: Teams, Users, Conversations...
    public func resyncResources() {
        managedObjectContext.performAndWait { [weak self] in
            guard let self else { return }
            // Refetch user settings.
            ZMUser.selfUser(in: managedObjectContext).needsPropertiesUpdate = true
            // If we don't have a last event id, we need to get that first, otherwise the quick sync will fetch all
            // events
            // in the notification queue.
            currentSyncPhase = hasPersistedLastEventID ? SyncPhase.fetchingLastUpdateEventID
                .nextPhase : .fetchingLastUpdateEventID
            RequestAvailableNotification.notifyNewRequestsAvailable(nil)
            logSyncStarted()
            syncStateDelegate?.didStartSlowSync()
        }
    }

    public func recoverWithQuickSync() async {
        isRecovering = true
        defer {
            self.isRecovering = false
        }
        await performQuickSync()
    }

    public func performQuickSync() async {
        await withCheckedContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume()
                return
            }

            // The continuation should be resumed when quick sync finishes.
            quickSyncContinuation = continuation
            currentSyncPhase = .fetchingMissedEvents
            RequestAvailableNotification.notifyNewRequestsAvailable(self)
        }
    }

    func notifyQuickSyncDidFinish() {
        syncStateDelegate?.didFinishQuickSync(isRecovering: isRecovering)
        quickSyncContinuation?.resume()
        quickSyncContinuation = nil
    }

    public func forceQuickSync() {
        isForceQuickSync = true
        currentSyncPhase = .fetchingMissedEvents
        resetSyncTimeTracker()
        WireLogger.sync.debug("quick sync", attributes: .safePublic)
        RequestAvailableNotification.notifyNewRequestsAvailable(self)

    }

}

// MARK: Slow Sync

public extension SyncStatus {

    func finishCurrentSyncPhase(phase: SyncPhase) {
        precondition(phase == currentSyncPhase, "Finished syncPhase does not match currentPhase '\(currentSyncPhase)'!")

        if phase.isLastSlowSyncPhase {
            persistLastUpdateEventID()
            syncStateDelegate?.didFinishSlowSync()
        }

        let didCompleteSync = isSlowSyncing ? phase.isLastSlowSyncPhase : phase.isLastQuickSyncPhase

        didCompleteSyncPhase(
            phase,
            completedAllPhases: didCompleteSync
        )

        currentSyncPhase = phase.nextPhase

        if currentSyncPhase == .done {
            if needsToRestartQuickSync, isPushChannelOpen {
                // If the push channel closed while fetching notifications
                // We need to restart fetching the notification stream since we might be missing notifications
                currentSyncPhase = .fetchingMissedEvents
                needsToRestartQuickSync = false
                WireLogger.sync
                    .debug(
                        "restarting quick sync since push channel was closed or open after request to fetch notifiations"
                    )
            } else {
                notifyQuickSyncDidFinish()
                isForceQuickSync = false
            }
        }
        RequestAvailableNotification.notifyNewRequestsAvailable(self)
    }

    func failCurrentSyncPhase(phase: SyncPhase) {
        precondition(phase == currentSyncPhase, "Failed syncPhase does not match currentPhase")

        WireLogger.sync.warn("failed sync phase: \(phase)")

        if currentSyncPhase == .fetchingMissedEvents {
            resetSyncTimeTracker()
            lastEventIDRepository.storeLastEventID(nil)
            currentSyncPhase = .fetchingLastUpdateEventID
            needsToRestartQuickSync = false
        }
    }

    internal var hasPersistedLastEventID: Bool {
        lastEventIDRepository.fetchLastEventID() != nil
    }

    func updateLastUpdateEventID(eventID: UUID) {
        WireLogger.sync.debug("update last eventID: \(eventID)")
        lastUpdateEventID = eventID
    }

    func persistLastUpdateEventID() {
        guard let lastUpdateEventID else { return }
        WireLogger.sync.debug("persist last eventID: \(lastUpdateEventID)")
        lastEventIDRepository.storeLastEventID(lastUpdateEventID)
    }

    func removeLastUpdateEventID() {
        lastUpdateEventID = nil
        WireLogger.sync.debug("remove last eventID")
        lastEventIDRepository.storeLastEventID(nil)
    }
}

// MARK: Quick Sync

public extension SyncStatus {

    func beganFetchingNotificationStream() {
        isFetchingNotificationStream = true
    }

    func failedFetchingNotificationStream() {
        if currentSyncPhase == .fetchingMissedEvents {
            failCurrentSyncPhase(phase: .fetchingMissedEvents)
        }

        isFetchingNotificationStream = false
    }

    @objc(completedFetchingNotificationStreamFetchBeganAt:)
    func completedFetchingNotificationStream(fetchBeganAt: Date?) {
        if currentSyncPhase == .fetchingMissedEvents {

            // Only complete the .fetchingMissedEvents phase if the push channel was
            // established before we initiated the notification stream fetch.
            // If the push channel disconnected in between we'll fetch the stream again
            if let pushChannelEstablishedDate, let fetchBeganAt, pushChannelEstablishedDate > fetchBeganAt {
                needsToRestartQuickSync = true
            }

            finishCurrentSyncPhase(phase: .fetchingMissedEvents)
        }

        isFetchingNotificationStream = false
    }

    func pushChannelDidClose() {
        Self.logger.trace("push channel did close")
        pushChannelEstablishedDate = nil

        if !currentSyncPhase.isSyncing {
            // As soon as the pushChannel closes we should notify the UI that we are syncing (if we are not already
            // syncing)
            logSyncStarted()
            syncStateDelegate?.didStartQuickSync()
        }
    }

    func pushChannelDidOpen() {
        Self.logger.trace("push channel did open")
        pushChannelEstablishedDate = Date()

        if currentSyncPhase == .fetchingMissedEvents {
            // If the push channel closed while we are fetching the notifications, we might be missing notifications
            // that
            // were sent between the server response and the channel re-opening We therefore need to mark the quick sync
            // to be re-started
            needsToRestartQuickSync = true
        }

        if !currentSyncPhase.isSyncing {
            // When the push channel opens we need to start syncing (if we are not already syncing)
            currentSyncPhase = .fetchingMissedEvents
        }
    }

    private func didCompleteSyncPhase(
        _ phase: SyncPhase,
        completedAllPhases: Bool
    ) {
        let currentTime = Date.now
        let phaseStartTime = syncTimeTracker.phaseStartTime
        let duration = currentTime.timeIntervalSince(phaseStartTime)

        logSyncPhaseCompleted(phase: phase, duration: duration)
        syncTimeTracker.addPhaseDuration(duration)
        // resetting for next sync phase
        syncTimeTracker.resetStartTime()

        if completedAllPhases {
            logSyncCompleted()
            // Sync is completed and logged, resetting tracked time values
            resetSyncTimeTracker()
        }
    }

    func resetSyncTimeTracker() {
        syncTimeTracker.reset()
    }
}

// MARK: - Logging

extension SyncStatus {

    /// Logs the initial / incremental sync start
    private func logSyncStarted() {
        let message = "starting \(isSlowSyncing ? "legacy initial sync" : "legacy incremental sync")"

        WireLogger.sync.info(
            message,
            attributes: .legacySyncDidStartAttributes(
                initialSync: isSlowSyncing
            )
        )
    }

    /// Logs the initial or incremental sync completion with the related duration
    private func logSyncCompleted() {
        let syncTotalDuration = syncTimeTracker.totalSyncDuration()
        let formattedDuration = String(format: "%.2f", syncTotalDuration)

        let message =
            "completed \(isSlowSyncing ? "legacy initial sync" : "legacy incremental sync")"

        WireLogger.sync.info(
            message,
            attributes: .legacySyncDidFinishAttributes(
                duration: formattedDuration,
                initialSync: isSlowSyncing
            )
        )
    }

    /// Logs the initial / incremental sync phase starting
    private func logSyncPhaseStarted(
        phase: SyncPhase
    ) {
        WireLogger.sync.info(
            "starting sync phase",
            attributes: .legacySyncPhaseDidStartAttributes(
                phase.description,
                initialSync: isSlowSyncing
            )
        )
    }

    /// Logs the initial / incremental sync phase completion with the related duration
    private func logSyncPhaseCompleted(
        phase: SyncPhase,
        duration: Double
    ) {
        let formattedDuration = String(format: "%.2f", duration)
        let message = "completed sync phase"

        WireLogger.sync.info(
            message,
            attributes: .legacySyncPhaseDidCompleteAttributes(
                phase.description,
                duration: formattedDuration,
                initialSync: isSlowSyncing
            )
        )
    }
}
