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

    private let incrementalSyncTaskManager = NonReentrantTaskManager()
    private var incrementalSyncToken: IncrementalSync.Token?
<<<<<<< HEAD
=======
    private var ongoingSyncTask: Task<Void, Never>?
    private var subscription: AnyCancellable?
>>>>>>> e27bb3c2af (fix: message sending stuck - WPB-17866 (#3100))

    private var hasCompletedInitialSync: Bool {
        lastUpdateEventIDRepository.fetchLastEventID() != nil
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
        syncStateSubject: CurrentValueSubject<SyncState, Never>
    ) {
        self.journal = journal
        self.lastUpdateEventIDRepository = lastUpdateEventIDRepository
        self.coreCryptoProvider = coreCryptoProvider
        self.initialSyncProvider = initialSyncProvider
        self.incrementalSyncProvider = incrementalSyncProvider
        self.legacySyncStatus = legacySyncStatus
        self.syncStateSubject = syncStateSubject
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
<<<<<<< HEAD
        Task {
=======
        syncStateSubject.send(.idle)

        ongoingSyncTask = Task {
            WireLogger.sync.debug(
                "resuming sync"
            )

>>>>>>> e27bb3c2af (fix: message sending stuck - WPB-17866 (#3100))
            let retrier = BackoffRetrier()

            do {
                try await retrier.retry { [self] in
                    try await performSync()
                }
            } catch {
                delegate?.syncAgentDidFailSyncing(
                    self,
                    error: error
                )
            }
        }
    }

    /// Suspend any ongoing sync tasks.

    func suspend() {
        Task {
            await suspend()
        }
    }

    private func suspend() async {
        WireLogger.sync.debug("suspending sync")
        await incrementalSyncToken?.suspend()
        incrementalSyncToken = nil
        syncStateSubject.send(.suspended)
    }

    /// Performs the appropriate sync depending in the local state.
    ///
    /// If no last event id is known, then the initial sync will be performed,
    /// otherwise the incremental sync will be performed.

    func performSync() async throws {
        if !hasCompletedInitialSync {
            try await performInitialSync()
        } else {
            try await performIncrementalSync()
        }
    }

    /// Perform an initial sync.

    func performInitialSync() async throws {
        if isSyncV2Enabled {
            do {
                delegate?.syncAgentDidStartInitialSync(self)
                WireLogger.sync.debug("did start new initial sync")
                try await initialSyncProvider.provideInitialSync().perform(skipPullingLastUpdateEventID: false)
                WireLogger.sync.debug("did finish new initial sync")
                journal[.isInitialSyncRequired] = false
                delegate?.syncAgentDidFinishInitialSync(self)
            } catch {
                WireLogger.sync.error("failed to perform new initial sync: \(String(describing: error))")
                throw error
            }

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
                delegate?.syncAgentDidStartInitialSync(self)
                WireLogger.sync.debug("did start new resource sync")
                try await initialSyncProvider.provideInitialSync().perform(skipPullingLastUpdateEventID: true)
                WireLogger.sync.debug("did finish new resource sync")
                delegate?.syncAgentDidFinishInitialSync(self)
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
        if isSyncV2Enabled {
            guard incrementalSyncToken == nil else {
                WireLogger.sync.info("incremental sync already running...")
                return
            }

            do {
                try await incrementalSyncTaskManager.performIfNeeded { [weak self] in
                    guard let self else { return }
                    delegate?.syncAgentDidStartIncrementalSync(self)
                    incrementalSyncToken = try await incrementalSyncProvider.provideIncrementalSync().perform()
                    delegate?.syncAgentDidFinishIncrementalSync(self, isRecovering: false)
                }
            } catch {
                WireLogger.sync.error("failed to perform new incremental sync: \(String(describing: error))")
                syncStateSubject.send(.suspended)
                throw error
            }
        } else {
            await legacySyncStatus.performQuickSync()
        }
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
                    delegate?.syncAgentDidStartIncrementalSync(self)
                    incrementalSyncToken = try await incrementalSyncProvider.provideIncrementalSync().perform()
                    delegate?.syncAgentDidFinishIncrementalSync(self, isRecovering: true)
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
        WireLogger.sync.debug("did start legacy initial sync")
        delegate?.syncAgentDidStartLegacyInitialSync(self)
    }

    func didFinishSlowSync() {
        WireLogger.sync.debug("did finish legacy initial sync")
        delegate?.syncAgentDidFinishLegacyInitialSync(self)
    }

    func didStartQuickSync() {
        WireLogger.sync.debug("did start legacy incremental sync")
        delegate?.syncAgentDidStartLegacyIncrementalSync(self)
    }

    func didFinishQuickSync(isRecovering: Bool) {
        WireLogger.sync.debug("did finish legacy incremental sync")
        delegate?.syncAgentDidFinishLegacyIncrementalSync(self, isRecovering: isRecovering)
    }

}
