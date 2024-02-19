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

private let zmLog = ZMSLog(tag: "feature configurations")

public final class FeatureConfigRequestStrategy: AbstractRequestStrategy, GetFeatureConfigsActionHandlerDelegate {

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
            .allowsRequestsWhileOnline,
            .allowsRequestsDuringQuickSync,
            .allowsRequestsDuringSlowSync,
            .allowsRequestsWhileWaitingForWebsocket,
            .allowsRequestsWhileInBackground
        ]

        // getFeatureConfigsActionHandler.delegate = self
    }

    deinit {
        slowSyncTask?.cancel()
    }

    // MARK: - Request

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        if isSlowSyncing, slowSyncTask == nil {
            slowSyncTask = Task { [weak self, syncStatus, syncPhase] in
                guard let self, !Task.isCancelled else { return }

                WireLogger.conversation.info("FeatureConfigRequestStrategy: slow sync start fetch feature config!")

                do {
                    // perform action notifies the registered action handler `GetFeatureConfigsActionHandler`.
                    // the action stay pending until in the operation loop creates and executes the next request.
                    // Here the task waits for the result and then continues to report to syncStatus.

                    var action = GetFeatureConfigsAction()
                    try await action.perform(in: managedObjectContext.notificationContext)

                    WireLogger.conversation.info("FeatureConfigRequestStrategy: slow sync finished fetch feature config!")

                    await managedObjectContext.perform {
                        syncStatus.finishCurrentSyncPhase(phase: syncPhase)
                    }
                } catch {
                    WireLogger.conversation.error("FeatureConfigRequestStrategy: slow sync failed fetch feature config!")

                    await managedObjectContext.perform {
                        syncStatus.failCurrentSyncPhase(phase: syncPhase)
                    }
                }

                self.slowSyncTask = nil
            }
        }

        return actionSync.nextRequest(for: apiVersion)
    }

    // MARK: - GetFeatureConfigsActionHandlerDelegate

    func didFinishGetFeatureConfig() {
        if slowSyncTask == nil { return }
        WireLogger.conversation.info("FeatureConfigRequestStrategy: slow sync did finish fetch feature config!")
        syncStatus.finishCurrentSyncPhase(phase: syncPhase)
        self.slowSyncTask = nil
    }

    func didFailGetFeatureConfig() {
        if slowSyncTask == nil { return }
        WireLogger.conversation.info("FeatureConfigRequestStrategy: slow sync did fail fetch feature config!")
        syncStatus.failCurrentSyncPhase(phase: syncPhase)
        self.slowSyncTask = nil
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
            let payload = try JSONSerialization.data(withJSONObject: data, options: [])
            try processResponse(featureName: featureName, data: payload)
        } catch {
            zmLog.error("Failed to process feature config update event: \(error.localizedDescription)")
        }
    }

    private func processResponse(featureName: Feature.Name, data: Data) throws {
        let featureRepository = FeatureRepository(context: managedObjectContext)
        let decoder = JSONDecoder.defaultDecoder

        switch featureName {
        case .conferenceCalling:
            let response = try decoder.decode(FeatureStatus.self, from: data)
            featureRepository.storeConferenceCalling(.init(status: response.status))

        case .fileSharing:
            let response = try decoder.decode(FeatureStatus.self, from: data)
            featureRepository.storeFileSharing(.init(status: response.status))

        case .appLock:
            let response = try decoder.decode(FeatureStatusWithConfig<Feature.AppLock.Config>.self, from: data)
            featureRepository.storeAppLock(.init(status: response.status, config: response.config))

        case .selfDeletingMessages:
            let response = try decoder.decode(FeatureStatusWithConfig<Feature.SelfDeletingMessages.Config>.self, from: data)
            featureRepository.storeSelfDeletingMessages(.init(status: response.status, config: response.config))

        case .conversationGuestLinks:
            let response = try decoder.decode(FeatureStatus.self, from: data)
            featureRepository.storeConversationGuestLinks(.init(status: response.status))

        case .classifiedDomains:
            let response = try decoder.decode(FeatureStatusWithConfig<Feature.ClassifiedDomains.Config>.self, from: data)
            featureRepository.storeClassifiedDomains(.init(status: response.status, config: response.config))

        case .digitalSignature:
            let response = try decoder.decode(FeatureStatus.self, from: data)
            featureRepository.storeDigitalSignature(.init(status: response.status))

        case .mls:
            let response = try decoder.decode(FeatureStatusWithConfig<Feature.MLS.Config>.self, from: data)
            featureRepository.storeMLS(.init(status: response.status, config: response.config))

        case .mlsMigration:
            let response = try decoder.decode(FeatureStatusWithConfig<Feature.MLSMigration.Config>.self, from: data)
            featureRepository.storeMLSMigration(.init(status: response.status, config: response.config))
        }
    }

}

struct FeatureStatus: Codable {

    let status: Feature.Status

}

struct FeatureStatusWithConfig<Config: Codable>: Codable {

    let status: Feature.Status
    let config: Config

}
