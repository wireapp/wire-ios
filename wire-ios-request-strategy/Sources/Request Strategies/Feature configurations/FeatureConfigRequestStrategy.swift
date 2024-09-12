//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

public final class FeatureConfigRequestStrategy: AbstractRequestStrategy {

    // MARK: - Properties

    // Slow Sync

    private unowned var syncStatus: SyncProgress

    private let syncPhase: SyncPhase = .fetchingFeatureConfig

    private var isSlowSyncing: Bool { syncStatus.currentSyncPhase == syncPhase }

    private var slowSyncTask: Task<Void, Never>?

    // Action

    private let actionHandler: GetFeatureConfigsActionHandler
    private let actionSync: EntityActionSync

    // MARK: - Life cycle

    public init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus,
        syncProgress: SyncProgress
    ) {
        actionHandler = GetFeatureConfigsActionHandler(context: managedObjectContext)
        actionSync = EntityActionSync(actionHandlers: [actionHandler])
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

                WireLogger.featureConfigs.info("slow sync start fetch feature config!")

                do {
                    // perform action notifies the registered action handler `GetFeatureConfigsActionHandler`.
                    // the action stay pending until in the operation loop creates and executes the next request.
                    // Here the task waits for the result and then continues to report to syncStatus.

                    var action = GetFeatureConfigsAction()
                    try await action.perform(in: managedObjectContext.notificationContext)

                    WireLogger.featureConfigs.info("slow sync finished fetch feature config!")

                    await managedObjectContext.perform {
                        syncStatus.finishCurrentSyncPhase(phase: syncPhase)
                    }
                } catch {
                    WireLogger.featureConfigs.error("slow sync failed fetch feature config!")

                    await managedObjectContext.perform {
                        syncStatus.failCurrentSyncPhase(phase: syncPhase)
                    }
                }

                self.slowSyncTask = nil
            }
        }

        return actionSync.nextRequest(for: apiVersion)
    }
}

// MARK: - Event processing

extension FeatureConfigRequestStrategy: ZMEventConsumer {

    public func processEvents(
        _ events: [ZMUpdateEvent],
        liveEvents: Bool,
        prefetchResult: ZMFetchRequestBatchResult?
    ) {
        events.forEach(processEvent)
    }

    private func processEvent(_ event: ZMUpdateEvent) {
        guard
            event.type == .featureConfigUpdate,
            let name = event.payload["name"] as? String,
            let featureName = Feature.Name(rawValue: name),
            let data = event.payload["data"]
        else {
            return
        }

        do {
            WireLogger.featureConfigs.info("Process update event '\(name)'")

            let payloadData = try JSONSerialization.data(withJSONObject: data, options: [])
            let repository = FeatureRepository(context: managedObjectContext)

            let processor = FeatureConfigsPayloadProcessor()
            try processor.processEventPayload(
                data: payloadData,
                featureName: featureName,
                repository: repository)

            WireLogger.featureConfigs.info("Finished processing update event \(name)")
        } catch {
            WireLogger.featureConfigs.error("Failed processing update event \(name): \(error.localizedDescription)")
        }
    }

}
