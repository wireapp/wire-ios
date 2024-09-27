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

private let zmLog = ZMSLog(tag: "SyncStatus")

extension Notification.Name {
    public static let initialSync = Notification.Name("ZMInitialSyncCompletedNotification")
    public static let resyncResources = Notification.Name("resyncResourcesNotificationName")

    static let triggerQuickSync = Notification.Name("triggerQuickSync")
}

// MARK: - SyncStatus

@objcMembers
public class SyncStatus: NSObject, SyncStatusProtocol, SyncProgress {
    private static let logger = Logger(subsystem: "VoIP Push", category: "SyncStatus")

    public internal(set) var currentSyncPhase: SyncPhase = .done {
        didSet {
            if currentSyncPhase != oldValue {
                log()
                zmLog.debug("did change sync phase: \(currentSyncPhase)")
                notifySyncPhaseDidStart()
            }
        }
    }

    weak var syncStateDelegate: ZMSyncStateDelegate?

    private let lastEventIDRepository: LastEventIDRepositoryInterface
    fileprivate var lastUpdateEventID: UUID?
    fileprivate unowned var managedObjectContext: NSManagedObjectContext
    fileprivate var resyncResourcesToken: Any?

    public internal(set) var isFetchingNotificationStream = false
    public internal(set) var isInBackground = false
    public internal(set) var needsToRestartQuickSync = false
    public internal(set) var pushChannelEstablishedDate: Date?

    var quickSyncContinuation: CheckedContinuation<Void, Never>?

    public var isSlowSyncing: Bool {
        !currentSyncPhase.isOne(of: [.fetchingMissedEvents, .done])
    }

    private var isForceQuickSync = false

    public var isSyncing: Bool {
        currentSyncPhase.isSyncing || !isPushChannelOpen
    }

    public var isSyncingInBackground: Bool {
        currentSyncPhase.isSyncing
    }

    public var isPushChannelOpen: Bool {
        pushChannelEstablishedDate != nil
    }

    public init(
        managedObjectContext: NSManagedObjectContext,
        lastEventIDRepository: LastEventIDRepositoryInterface
    ) {
        self.managedObjectContext = managedObjectContext
        self.lastEventIDRepository = lastEventIDRepository

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
            syncStateDelegate?.didStartQuickSync()
        case .fetchingLastUpdateEventID:
            syncStateDelegate?.didStartSlowSync()
        default:
            break
        }
    }

    public func determineInitialSyncPhase() {
        currentSyncPhase = hasPersistedLastEventID ? .fetchingMissedEvents : .fetchingLastUpdateEventID
        notifySyncPhaseDidStart()
    }

    public func forceSlowSync() {
        // Refetch user settings.
        ZMUser.selfUser(in: managedObjectContext).needsPropertiesUpdate = true
        // Reset the status.
        currentSyncPhase = SyncPhase.fetchingLastUpdateEventID
        log("slow sync")
        syncStateDelegate?.didStartSlowSync()
    }

    /// Sync the resources: Teams, Users, Conversations...
    func resyncResources() {
        // Refetch user settings.
        ZMUser.selfUser(in: managedObjectContext).needsPropertiesUpdate = true
        // Set the status.
        currentSyncPhase = SyncPhase.fetchingLastUpdateEventID.nextPhase
        log("resyncResources")
        syncStateDelegate?.didStartSlowSync()
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
        syncStateDelegate?.didFinishQuickSync()
        quickSyncContinuation?.resume()
        quickSyncContinuation = nil
    }

    public func forceQuickSync() {
        isForceQuickSync = true
        currentSyncPhase = .fetchingMissedEvents
        log("quick sync")
        RequestAvailableNotification.notifyNewRequestsAvailable(self)
    }
}

// MARK: Slow Sync

extension SyncStatus {
    public func finishCurrentSyncPhase(phase: SyncPhase) {
        precondition(phase == currentSyncPhase, "Finished syncPhase does not match currentPhase '\(currentSyncPhase)'!")

        log("finished sync phase")

        if phase.isLastSlowSyncPhase {
            persistLastUpdateEventID()
            syncStateDelegate?.didFinishSlowSync()
        }

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
                WireLogger.sync.debug("sync complete")
                notifyQuickSyncDidFinish()
                isForceQuickSync = false
            }
        }
        RequestAvailableNotification.notifyNewRequestsAvailable(self)
    }

    public func failCurrentSyncPhase(phase: SyncPhase) {
        precondition(phase == currentSyncPhase, "Failed syncPhase does not match currentPhase")

        WireLogger.sync.warn("failed sync phase: \(phase)")

        if currentSyncPhase == .fetchingMissedEvents {
            lastEventIDRepository.storeLastEventID(nil)
            currentSyncPhase = .fetchingLastUpdateEventID
            needsToRestartQuickSync = false
        }
    }

    var hasPersistedLastEventID: Bool {
        lastEventIDRepository.fetchLastEventID() != nil
    }

    public func updateLastUpdateEventID(eventID: UUID) {
        WireLogger.sync.debug("update last eventID: \(eventID)")
        lastUpdateEventID = eventID
    }

    public func persistLastUpdateEventID() {
        guard let lastUpdateEventID else { return }
        WireLogger.sync.debug("persist last eventID: \(lastUpdateEventID)")
        lastEventIDRepository.storeLastEventID(lastUpdateEventID)
    }

    public func removeLastUpdateEventID() {
        lastUpdateEventID = nil
        WireLogger.sync.debug("remove last eventID")
        lastEventIDRepository.storeLastEventID(nil)
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
        WireLogger.sync
            .debug("completedFetchingNotificationStream began at: \(fetchBeganAt?.description ?? "<unknown>")")
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

    public func pushChannelDidClose() {
        Self.logger.trace("push channel did close")
        pushChannelEstablishedDate = nil

        if !currentSyncPhase.isSyncing {
            // As soon as the pushChannel closes we should notify the UI that we are syncing (if we are not already
            // syncing)
            syncStateDelegate?.didStartQuickSync()
        }
    }

    public func pushChannelDidOpen() {
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

    private func log(_ message: String? = nil) {
        let info = SyncStatusLog(
            phase: currentSyncPhase.description,
            isSyncing: isSyncing,
            pushChannelEstablishedDate: pushChannelEstablishedDate?.description,
            message: message
        )
        do {
            let data = try JSONEncoder().encode(info)
            let jsonString = String(decoding: data, as: UTF8.self)
            let message = "SYNC_STATUS: \(jsonString)"
            WireLogger.sync.info(message, attributes: .safePublic)
        } catch {
            let message = "SYNC_STATUS: \(description)"
            WireLogger.sync.error(message, attributes: .safePublic)
        }
    }
}
