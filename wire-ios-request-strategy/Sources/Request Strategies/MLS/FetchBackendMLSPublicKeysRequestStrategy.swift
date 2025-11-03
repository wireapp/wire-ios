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
import WireLegacyLogging

public final class FetchBackendMLSPublicKeysRequestStrategy: AbstractRequestStrategy {

    // MARK: - Properties

    // Slow Sync

    private unowned var syncStatus: SyncProgress

    private let syncPhase: SyncPhase = .fetchingBackendMLSPublicKeys

    private var isSlowSyncing: Bool { syncStatus.currentSyncPhase == syncPhase }

    private var slowSyncTask: Task<Void, Never>?

    // Action

    private let actionHandler: FetchBackendMLSPublicKeysActionHandler
    private let actionSync: EntityActionSync

    // MARK: - Life cycle

    public init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus,
        syncProgress: SyncProgress
    ) {
        self.actionHandler = FetchBackendMLSPublicKeysActionHandler(context: managedObjectContext)
        self.actionSync = EntityActionSync(actionHandlers: [actionHandler])
        self.syncStatus = syncProgress

        super.init(
            withManagedObjectContext: managedObjectContext,
            applicationStatus: applicationStatus
        )

        configuration = [
            .allowsRequestsWhileUnauthenticated,
            .allowsRequestsWhileOnline,
            .allowsRequestsDuringQuickSync,
            .allowsRequestsDuringSlowSync,
            .allowsRequestsWhileWaitingForWebsocket,
            .allowsRequestsWhileInBackground
        ]
    }

    deinit {
        slowSyncTask?.cancel()
    }

    // MARK: - Request

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        if isSlowSyncing, slowSyncTask == nil {
            slowSyncTask = Task { [weak self, syncStatus, syncPhase] in
                guard let self, !Task.isCancelled else { return }

                WireLogger.mls.info("slow sync start fetch backend MLS public keys!")

                do {
                    // perform action notifies the registered action handler `FetchBackendMLSPublicKeysActionHandler`.
                    // the action stay pending until in the operation loop creates and executes the next request.
                    // Here the task waits for the result and then continues to report to syncStatus.

                    var action = FetchBackendMLSPublicKeysAction()
                    let backendPublicKeys = try await action.perform(in: managedObjectContext.notificationContext)
                    let hasValidKeys = backendPublicKeys.removal.hasValidKeys()
                    BackendInfo.isMLSEnabled = hasValidKeys

                    WireLogger.mls.info("slow sync finished fetch backend MLS public keys!")
                } catch {
                    // If we get an error while fetching MLS public keys,
                    // it shouldn't fail the current phase. This is expected behavior for some customers.
                    // More details here: https://wearezeta.atlassian.net/browse/WPB-14455
                    BackendInfo.isMLSEnabled = false

                    WireLogger.mls.info("slow sync can't fetch backend MLS public keys!")
                }
                await managedObjectContext.perform {
                    syncStatus.finishCurrentSyncPhase(phase: syncPhase)
                }

                slowSyncTask = nil
            }
        }

        return actionSync.nextRequest(for: apiVersion)
    }
}
