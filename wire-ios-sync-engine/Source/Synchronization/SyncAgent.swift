//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
    private let initialSyncProvider: any InitialSyncProvider
    private let incrementalSyncProvider: any IncrementalSyncProvider
    private let coreCryptoProvider: any CoreCryptoProviderProtocol
    private let featureConfigRepository: any FeatureConfigRepositoryProtocol
    private let pushChannelCoordinator: any MainAppPushChannelCoordinatorProtocol
    private let networkStatePublisher: AnyPublisher<NetworkState, Never>
    private let incrementalSyncTaskManager = NonReentrantTaskManager<Void, any Error>()
    private let initialSyncTaskManager = NonReentrantTaskManager<Void, any Error>()
    private var incrementalSyncToken: IncrementalSync.Token?
    private var ongoingSyncTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = .init()

    var syncRunning: Bool {
        ongoingSyncTask != nil || incrementalSyncToken != nil
    }

    var isLive: Bool {
        syncStateSubject.value == .liveSyncing(.ongoing)
    }

    // MARK: - Life cycle

    init(
        journal: Journal,
        coreCryptoProvider: any CoreCryptoProviderProtocol,
        initialSyncProvider: any InitialSyncProvider,
        incrementalSyncProvider: any IncrementalSyncProvider,
        featureConfigRepository: any FeatureConfigRepositoryProtocol,
        syncStateSubject: CurrentValueSubject<SyncState, Never>,
        pushChannelCoordinator: any MainAppPushChannelCoordinatorProtocol,
        networkStatePublisher: AnyPublisher<NetworkState, Never>
    ) {
        self.journal = journal
        self.coreCryptoProvider = coreCryptoProvider
        self.initialSyncProvider = initialSyncProvider
        self.incrementalSyncProvider = incrementalSyncProvider
        self.featureConfigRepository = featureConfigRepository
        self.syncStateSubject = syncStateSubject
        self.pushChannelCoordinator = pushChannelCoordinator
        self.networkStatePublisher = networkStatePublisher
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
    ///
    /// - Parameter forCallEventsOnly: if the sync should be resumed only for calling events

    func resume(forCallEventsOnly: Bool = false) {
        syncStateSubject.send(.idle)

        ongoingSyncTask = Task {
            WireLogger.sync.debug("resuming sync")
            do {
                // because we might be interrupted when in background, we wrap the sync in an expiringActivity that will
                // cancel the task (not keeping any file lock in suspend mode)
                try await withExpiringActivity(reason: "resuming sync") { [weak self] in
                    if forCallEventsOnly {
                        try await self?.performIncrementalSyncForCallingEvents()
                    } else {
                        try await self?.performSync()
                    }
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
        try await performInitialSyncV2()
        try await performIncrementalSync()
    }

    /// Perform a resource sync.

    func performResourceSync() async throws {
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
    }

    /// Perform an incremental sync.

    func performIncrementalSync() async throws {
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
                } catch IncrementalSync.Failure.databaseLocked {
                    syncStateSubject.send(.suspended)
                    // ignore error and don't retry, the sync will be resumed once the app is unlocked
                } catch {
                    WireLogger.sync.error("failed to perform new incremental sync: \(String(describing: error))")
                    syncStateSubject.send(.suspended)
                    throw error
                }
            }
        }
    }

    private func performIncrementalSyncForCallingEvents() async throws {
        try await incrementalSyncTaskManager.performIfNeeded { [weak self] in
            guard let self else { return }
            incrementalSyncToken = try await incrementalSyncProvider.provideIncrementalSync()
                .performInBackgroundForCallingEvents()
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
        syncStateSubject
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
            }.store(in: &cancellables)

        networkStatePublisher
            .receive(on: DispatchQueue.main)
            .scan((
                previous: NetworkState?.none,
                current: NetworkState?.none
            )) { state, newNetworkState -> (
                previous: NetworkState?,
                current: NetworkState?
            ) in
                (previous: state.current, current: newNetworkState)
            }
            .sink { [weak self] state in
                if state.current == .online, state.previous == .offline {
                    WireLogger.sync.warn("was offline, now back online, resume sync")
                    self?.resume()
                }
            }
            .store(in: &cancellables)
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
