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
import WireDataModel
import WireDomain
import WireLogging
import WireUtilities

// TODO: [WPB-15440] remove objc interoperability.
// To temporarily bridge this to legacy code, this inherits from NSObject
// and exposes a method to objc. Once we integrate the new incremental
// sync, we won't need to bridge to legacy code and remove the inheritance.

final class SyncAgent: NSObject {

    weak var delegate: SyncAgentDelegate?
    private let lastUpdateEventIDRepository: any LastEventIDRepositoryInterface
    private let initialSyncProvider: any InitialSyncProvider
    private let incrementalSyncProvider: any IncrementalSyncProvider
    private let legacySyncStatus: any SyncStatusProtocol

    private let incrementalSyncTaskManager = NonReentrantTaskManager()
    private var incrementalSyncTask: Task<Void, any Error>?

    private var hasCompletedInitialSync: Bool {
        lastUpdateEventIDRepository.fetchLastEventID() != nil
    }

    // MARK: - Life cycle

    init(
        lastUpdateEventIDRepository: any LastEventIDRepositoryInterface,
        initialSyncProvider: any InitialSyncProvider,
        incrementalSyncProvider: any IncrementalSyncProvider,
        legacySyncStatus: any SyncStatusProtocol
    ) {
        self.lastUpdateEventIDRepository = lastUpdateEventIDRepository
        self.initialSyncProvider = initialSyncProvider
        self.incrementalSyncProvider = incrementalSyncProvider
        self.legacySyncStatus = legacySyncStatus
        super.init()
    }

    // MARK: - API

    /// Performs the appropriate sync depending in the local state.
    ///
    /// If no last event id is known, then the initial sync will be performed,
    /// otherwise the incremental sync will be performed.

    func performSyncIfNeeded() async throws {
        if !hasCompletedInitialSync {
            try await performInitialSync()
        } else {
            try await performIncrementalSync()
        }
    }

    /// Perform an initial sync.

    func performInitialSync() async throws {
        if DeveloperFlag.newInitialSync.isOn {
            do {
                delegate?.syncAgentDidStartInitialSync(self)
                WireLogger.sync.debug("did start new initial sync")
                try await initialSyncProvider.provideInitialSync().perform(skipPullingLastUpdateEventID: false)
                WireLogger.sync.debug("did finish new initial sync")
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
        if DeveloperFlag.newInitialSync.isOn {
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
        if DeveloperFlag.newInitialSync.isOn {
            guard incrementalSyncTask == nil else {
                WireLogger.sync.info("incremental sync already running...")
                return
            }

            do {
                try await incrementalSyncTaskManager.performIfNeeded { [weak self] in
                    guard let self else { return }
                    delegate?.syncAgentDidStartIncrementalSync(self)
                    incrementalSyncTask = try await incrementalSyncProvider.provideIncrementalSync().perform()
                    delegate?.syncAgentDidFinishIncrementalSync(self)
                }
            } catch {
                WireLogger.sync.error("failed to perform new incremental sync: \(String(describing: error))")
                throw error
            }
        } else {
            await legacySyncStatus.performQuickSync()
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

    func didFinishQuickSync() {
        WireLogger.sync.debug("did finish legacy incremental sync")
        delegate?.syncAgentDidFinishLegacyIncrementalSync(self)
    }

}
