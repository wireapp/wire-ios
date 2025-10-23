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

import Combine
import Foundation
import WireDataModel
import WireDomain
import WireFoundation
import WireLogging
import WireUtilities

// sourcery: AutoMockable
protocol SyncAgentProtocol {

    var isSyncV2Enabled: Bool { get }
    var isLive: Bool { get }
    var syncStatePublisher: AnyPublisher<SyncState, Never> { get }

}

// TODO: [WPB-15440] remove objc interoperability.
// To temporarily bridge this to legacy code, this inherits from NSObject
// and exposes a method to objc. Once we integrate the new incremental
// sync, we won't need to bridge to legacy code and remove the inheritance.

final class SyncAgent: NSObject, SyncAgentProtocol {

    var isSyncV2Enabled: Bool {
        journal[.isSyncV2Enabled]
    }

    var isConsumableNotificationsEnabled: Bool {
        journal[.isConsumableNotificationsEnabled]
    }

    private let syncStateSubject: CurrentValueSubject<SyncState, Never>
    var syncStatePublisher: AnyPublisher<SyncState, Never> {
        syncStateSubject.eraseToAnyPublisher()
    }

    weak var delegate: SyncAgentDelegate?

    private let journal: Journal
    private let lastUpdateEventIDRepository: any LastEventIDRepositoryInterface
    private let initialSyncProvider: any InitialSyncProvider
    private let incrementalSyncProvider: any IncrementalSyncProvider
    private let legacySyncStatus: any SyncStatusProtocol
    private let coreCryptoProvider: any CoreCryptoProviderProtocol
    private let featureConfigRepository: any FeatureConfigRepositoryProtocol
    private let pushChannelCoordinator: any MainAppPushChannelCoordinatorProtocol

    private let incrementalSyncTaskManager = NonReentrantTaskManager()
    private let initialSyncTaskManager = NonReentrantTaskManager()
    private var incrementalSyncToken: IncrementalSync.Token?
    private var ongoingSyncTask: Task<Void, Never>?
    private let conversationsMonitor: ConversationUpdatesGeneratorProtocol

    private var subscription: AnyCancellable?

    var syncRunning: Bool {
        ongoingSyncTask != nil || incrementalSyncToken != nil
    }

    var isLive: Bool {
        if isSyncV2Enabled {
            syncStateSubject.value == .liveSyncing(.ongoing)
        } else {
            legacySyncStatus.isLive
        }
    }

    // MARK: - Life cycle

    init(
        journal: Journal,
        lastUpdateEventIDRepository: any LastEventIDRepositoryInterface,
        coreCryptoProvider: any CoreCryptoProviderProtocol,
        initialSyncProvider: any InitialSyncProvider,
        incrementalSyncProvider: any IncrementalSyncProvider,
        legacySyncStatus: any SyncStatusProtocol,
        featureConfigRepository: any FeatureConfigRepositoryProtocol,
        syncStateSubject: CurrentValueSubject<SyncState, Never>,
        pushChannelCoordinator: any MainAppPushChannelCoordinatorProtocol,
        conversationsMonitor: any ConversationUpdatesGeneratorProtocol
    ) {
        self.journal = journal
        self.lastUpdateEventIDRepository = lastUpdateEventIDRepository
        self.coreCryptoProvider = coreCryptoProvider
        self.initialSyncProvider = initialSyncProvider
        self.incrementalSyncProvider = incrementalSyncProvider
        self.legacySyncStatus = legacySyncStatus
        self.featureConfigRepository = featureConfigRepository
        self.syncStateSubject = syncStateSubject
        self.pushChannelCoordinator = pushChannelCoordinator
        self.conversationsMonitor = conversationsMonitor
        super.init()

        setupBindings()
    }

    // MARK: - API

    /// Trigger the appropriate sync depending in the local state.
    ///
    /// If no last event id is known, then the initial sync will be performed,
    /// otherwise the incremental sync will be performed.
    ///
    /// This method logs any errors and does not wait for the sync to finish.

    func resume() {
        syncStateSubject.send(.idle)

        ongoingSyncTask = Task {
            WireLogger.sync.debug(
                "resuming sync"
            )
            do {
                // because we might be interrupted when in background, we wrap the sync in an expiringActivity that will
                // cancel the task (not keeping any file lock in suspend mode)
                try await withExpiringActivity(reason: "resuming sync") { [weak self] in
                    try await self?.performSync()
                }
            } catch is CancellationError {
                // ignore error
            } catch {
                delegate?.syncAgentDidFailSyncing(
                    self,
                    error: error
                )
            }

        }
    }

    /// Suspend any ongoing sync tasks.

    func suspend() async {
        let backgroundActivity = BackgroundActivityFactory.shared.startBackgroundActivity(
            name: "suspending sync"
        )

        WireLogger.sync.debug(
            "suspending sync \(backgroundActivity != nil ? "in a background task" : "")"
        )
        conversationsMonitor.stop()
        ongoingSyncTask?.cancel()
        ongoingSyncTask = nil
        await incrementalSyncToken?.suspend()
        incrementalSyncToken = nil
        syncStateSubject.send(.suspended)

        if let backgroundActivity {
            BackgroundActivityFactory.shared.endBackgroundActivity(
                backgroundActivity
            )
        }
    }

    /// Performs the appropriate sync depending in the local state.
    ///
    /// If no last event id is known, then the initial sync will be performed,
    /// otherwise the incremental sync will be performed.

    func performSync() async throws {
        if journal[.isInitialSyncRequired] {
            try await performInitialSync()
        } else {
            try await performIncrementalSync()
        }
    }

    /// Perform an initial sync.

    func performInitialSync() async throws {
        if isSyncV2Enabled {
            try await performInitialSyncV2()
            try await performIncrementalSync()
        } else {
            // Incremental sync automatically follows the slow sync.
            legacySyncStatus.forceSlowSync()
        }
    }

    /// Perform a resource sync.

    func performResourceSync() async throws {
        if isSyncV2Enabled {
            do {
                try await initialSyncTaskManager.performIfNeeded { [weak self] in
                    guard let self else { return }
                    delegate?.syncAgentDidStartInitialSync(self)
                    WireLogger.sync.debug("did start new resource sync")
                    try await initialSyncProvider.provideInitialSync().perform(skipPullingLastUpdateEventID: true)
                    WireLogger.sync.debug("did finish new resource sync")
                    delegate?.syncAgentDidFinishInitialSync(self)
                }
            } catch {
                WireLogger.sync.error("failed to perform new resource sync: \(String(describing: error))")
                throw error
            }

            try await performIncrementalSync()
        } else {
            // Incremental sync automatically follows the resource sync.
            legacySyncStatus.resyncResources()
        }
    }

    /// Perform an incremental sync.

    func performIncrementalSync() async throws {
        Task {
            await conversationsMonitor.start()
        }

        if isSyncV2Enabled {

            try await incrementalSyncTaskManager.performIfNeeded { [weak self] in
                guard let self else { return }

                let retrier = BackoffRetrier()

                try await retrier.retry { [weak self] in
                    guard let self else { return }

                    do {
                        if isConsumableNotificationsEnabled {
                            incrementalSyncToken = try await incrementalSyncProvider.provideLiveSync(delegate: self)
                                .perform()
                        } else {
                            delegate?.syncAgentDidStartIncrementalSync(self)
                            incrementalSyncToken = try await incrementalSyncProvider.provideIncrementalSync()
                                .perform()
                            delegate?.syncAgentDidFinishIncrementalSync(self, isRecovering: false)
                        }
                    } catch IncrementalSyncV2.Failure.mainAppPushChannelAlreadyOpened {
                        syncStateSubject.send(.suspended)
                        // ignore error, don't retry
                        // this can happen if receiving a call
                    } catch IncrementalSyncV2.Failure.nsePushChannelAlreadyOpened {
                        WireLogger.sync.debug(
                            "push channel opened, waiting until closed",
                            attributes: .incrementalSyncV3
                        )
                        await pushChannelCoordinator.signalToExtensionsToYieldPushChannel()
                        WireLogger.sync.debug(
                            "retry sync after NSE push channel closed",
                            attributes: .incrementalSyncV3
                        )

                        syncStateSubject.send(.suspended)
                        // swallow error from retrier and start resume
                        resume()

                    } catch IncrementalSync.Failure.missedEvents {

                        WireLogger.sync.error(
                            "failed to perform new incremental sync (missed events): recovering with a full sync"
                        )

                        journal[.isInitialSyncRequired] = true
                        syncStateSubject.send(.suspended)
                        // swallow error from retrier and start resume
                        resume()
                    } catch {
                        WireLogger.sync.error("failed to perform new incremental sync: \(String(describing: error))")
                        syncStateSubject.send(.suspended)
                        throw error
                    }
                }

            }

        } else {
            await legacySyncStatus.performQuickSync()
        }
    }

    private func performInitialSyncV2() async throws {
        try await initialSyncTaskManager.performIfNeeded {
            let retrier = BackoffRetrier()

            try await retrier.retry { [self] in
                do {
                    delegate?.syncAgentDidStartInitialSync(self)
                    WireLogger.sync.debug("did start new initial sync")
                    try await initialSyncProvider.provideInitialSync()
                        .perform(skipPullingLastUpdateEventID: skipPullingLastNotificationID)
                    WireLogger.sync.debug("did finish new initial sync")
                    journal[.isInitialSyncRequired] = false
                    delegate?.syncAgentDidFinishInitialSync(self)
                } catch {
                    WireLogger.sync.error("failed to perform new initial sync: \(String(describing: error))")
                    throw error
                }
            }
        }
    }

    private var skipPullingLastNotificationID: Bool {
        journal[.isConsumableNotificationsEnabled]
    }

    private func setupBindings() {
        subscription = syncStateSubject
            .receive(on: DispatchQueue.main)
            .filter {
                let liveSyncTerminated = $0 == .liveSyncing(.finished)
                let isAppInForeground = UIApplication.shared.applicationState != .background

                return liveSyncTerminated && isAppInForeground
            }
            .sink { [weak self] _ in
                // if live sync terminated and we're in foreground
                // app will try to recover by performing an incremental sync again
                self?.resume()
            }
    }
}

extension SyncAgent: LiveSyncDelegate {

    func isUpToDate(sync: IncrementalSyncV2) {
        delegate?.syncAgentDidFinishIncrementalSync(self, isRecovering: false)
    }

    func didMissedEvents(sync: IncrementalSyncV2) async {
        WireLogger.sync.debug("slow sync requested by sync v3")
        do {
            try await performInitialSyncV2()
            WireLogger.sync.debug("slow sync done, should ack full sync")
        } catch {
            WireLogger.sync.error("error while requesing slow sync: \(error.localizedDescription)")
        }
    }

    func didFail(sync: IncrementalSyncV2, error: any Error) {
        guard !(error is CancellationError) else { return }
        delegate?.syncAgentDidFailSyncing(
            self,
            error: error
        )
    }

    func didStart(sync: IncrementalSyncV2) {
        delegate?.syncAgentDidStartIncrementalSync(self)
    }

}

// MARK: - MLS sync delegate

extension SyncAgent: MLSSyncDelegate {

    func recoverWithIncrementalSync() async throws {
        WireLogger.sync.info("performing recovery incremental sync")

        if isSyncV2Enabled {
            // Recovery means to restart any existing sync.
            await suspend()

            do {
                try await incrementalSyncTaskManager.performIfNeeded { [weak self] in
                    guard let self else { return }

                    if isConsumableNotificationsEnabled {
                        incrementalSyncToken = try await incrementalSyncProvider.provideLiveSync(delegate: self)
                            .perform()
                    } else {
                        delegate?.syncAgentDidStartIncrementalSync(self)
                        incrementalSyncToken = try await incrementalSyncProvider.provideIncrementalSync()
                            .perform()
                        delegate?.syncAgentDidFinishIncrementalSync(self, isRecovering: false)
                    }
                }
            } catch {
                WireLogger.sync.error("failed to perform recovery incremental sync: \(String(describing: error))")
                throw error
            }
        } else {
            await legacySyncStatus.recoverWithQuickSync()
        }
    }

}

// MARK: - Delegate

// Forward delegate calls from legacy sync status to the
// sync agent's delegate. We can delete this once we
// move to the new initial sync.

extension SyncAgent: ZMSyncStateDelegate {

    func didStartSlowSync() {
        delegate?.syncAgentDidStartLegacyInitialSync(self)
    }

    func didFinishSlowSync() {
        delegate?.syncAgentDidFinishLegacyInitialSync(self)
    }

    func didStartQuickSync() {
        delegate?.syncAgentDidStartLegacyIncrementalSync(self)
    }

    func didFinishQuickSync(isRecovering: Bool) {
        delegate?.syncAgentDidFinishLegacyIncrementalSync(
            self,
            isRecovering: isRecovering
        )
    }

}
