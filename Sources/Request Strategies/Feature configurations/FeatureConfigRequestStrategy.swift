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

public extension Notification.Name {
    static let fetchAllConfigsTriggerNotification = Notification.Name("fetchAllConfigsTriggerNotification")
}

@objcMembers
public final class FeatureConfigRequestStrategy: AbstractRequestStrategy, ZMContextChangeTrackerSource {

    // MARK: - Properties

    private var needsToFetchAllConfigs = false {
        didSet {
            guard needsToFetchAllConfigs else { return }
            fetchAllConfigsSync.readyForNextRequestIfNotBusy()
            RequestAvailableNotification.notifyNewRequestsAvailable(self)
        }
    }

    private var fetchSingleConfigSync: ZMDownstreamObjectSync!
    private var fetchAllConfigsSync: ZMSingleRequestSync!

    private var team: Team? {
        return ZMUser.selfUser(in: managedObjectContext).team
    }

    private var observerToken: Any?

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [fetchSingleConfigSync]
    }

    // MARK: - Init

    public override init(withManagedObjectContext managedObjectContext: NSManagedObjectContext,
                         applicationStatus: ApplicationStatus) {

        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)
        
        configuration = [
            .allowsRequestsWhileOnline,
            .allowsRequestsDuringQuickSync,
            .allowsRequestsWhileWaitingForWebsocket,
            .allowsRequestsWhileInBackground
        ]

        fetchSingleConfigSync = ZMDownstreamObjectSync(
            transcoder: self,
            entityName: Feature.entityName(),
            predicateForObjectsToDownload: Feature.predicateForNeedingToBeUpdatedFromBackend(),
            managedObjectContext: managedObjectContext
        )

        fetchAllConfigsSync = ZMSingleRequestSync(singleRequestTranscoder: self, groupQueue: managedObjectContext)

        observerToken = NotificationCenter.default.addObserver(
            forName: .fetchAllConfigsTriggerNotification,
            object: nil,
            queue: nil,
            using: { [weak self] _ in self?.needsToFetchAllConfigs = true }
        )
    }

    // MARK: - Overrides

    public override func nextRequestIfAllowed() -> ZMTransportRequest? {
        return fetchAllConfigsSync.nextRequest() ?? fetchSingleConfigSync.nextRequest()
    }

}

// MARK: - Single config transcoder

extension FeatureConfigRequestStrategy: ZMDownstreamTranscoder {

    public func request(forFetching object: ZMManagedObject!, downstreamSync: ZMObjectSync!) -> ZMTransportRequest! {
        guard let feature = object as? Feature else { fatal("Wrong sync or object for: \(object.safeForLoggingDescription)") }
        return requestToFetchConfig(for: feature)
    }

    private func requestToFetchConfig(for feature: Feature) -> ZMTransportRequest? {
        return ZMTransportRequest(getFromPath: "/feature-configs/\(feature.transportName)")
    }

    public func update(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        guard
            (downstreamSync as? ZMDownstreamObjectSync) == self.fetchSingleConfigSync,
            let feature = object as? Feature,
            response.result == .success,
            let responseData = response.rawData
        else {
            return
        }

        do {
            try processResponse(featureName: feature.name, data: responseData)
            feature.needsToBeUpdatedFromBackend = false
        } catch {
            zmLog.error("Failed to process feature config response: \(error.localizedDescription)")
        }
    }

    public func delete(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        // No op
    }

    private func processResponse(featureName: Feature.Name, data: Data) throws {
        let featureService = FeatureService(context: managedObjectContext)
        let decoder = JSONDecoder()

        switch featureName {
        case .conferenceCalling:
            let response = try decoder.decode(SimpleConfigResponse.self, from: data)
            featureService.storeConferenceCalling(.init(status: response.status))

        case .fileSharing:
            let response = try decoder.decode(SimpleConfigResponse.self, from: data)
            featureService.storeFileSharing(.init(status: response.status))

        case .appLock:
            let response = try decoder.decode(ConfigResponse<Feature.AppLock.Config>.self, from: data)
            featureService.storeAppLock(.init(status: response.status, config: response.config))

        case .selfDeletingMessages:
            let response = try decoder.decode(ConfigResponse<Feature.SelfDeletingMessages.Config>.self, from: data)
            featureService.storeSelfDeletingMessages(.init(status: response.status, config: response.config))
        }
    }

}

// MARK: - All configs transcoder

extension FeatureConfigRequestStrategy: ZMSingleRequestTranscoder {

    public func request(for sync: ZMSingleRequestSync) -> ZMTransportRequest? {
        guard sync == fetchAllConfigsSync else { return nil }
        return requestToFetchAllFeatureConfigs()
    }

    private func requestToFetchAllFeatureConfigs() -> ZMTransportRequest? {
        guard let teamId = team?.remoteIdentifier?.transportString() else { return nil }
        return ZMTransportRequest(getFromPath: "/teams/\(teamId)/features")
    }

    public func didReceive(_ response: ZMTransportResponse, forSingleRequest sync: ZMSingleRequestSync) {
        guard
            sync == fetchAllConfigsSync,
            response.result == .success,
            let responseData = response.rawData
        else {
            return
        }

        do {
            let allConfigs = try JSONDecoder().decode(AllConfigsResponse.self, from: responseData)

            let featureService = FeatureService(context: managedObjectContext)
            featureService.storeAppLock(.init(status: allConfigs.applock.status, config: allConfigs.applock.config))
            featureService.storeFileSharing(.init(status: allConfigs.fileSharing.status))
            featureService.storeSelfDeletingMessages(.init(status: allConfigs.selfDeletingMessages.status, config: allConfigs.selfDeletingMessages.config))

        } catch {
            zmLog.error("Failed to decode feature config response: \(error)")
        }
    }
}

//MARK: - ZMEventConsumer

extension FeatureConfigRequestStrategy: ZMEventConsumer {

    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
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

}

// MARK: - Response models

private struct AllConfigsResponse: Decodable {

    let applock: ConfigResponse<Feature.AppLock.Config>
    let fileSharing: SimpleConfigResponse
    let selfDeletingMessages: ConfigResponse<Feature.SelfDeletingMessages.Config>

}

private struct SimpleConfigResponse: Decodable {

    let status: Feature.Status

}

private struct ConfigResponse<T: Decodable>: Decodable {

    let status: Feature.Status
    let config: T

}

// MARK: - Helpers

private extension Feature {

    /// The name to use in the endpoint.

    var transportName: String {
        switch name {
        case .appLock:
            return "appLock"

        case .conferenceCalling:
            return "conferenceCalling"
            
        case .fileSharing:
            return "fileSharing"

        case .selfDeletingMessages:
            return "selfDeletingMessages"
        }
    }

}

public extension Feature {

    static func triggerBackendRefreshForAllConfigs() {
        NotificationCenter.default.post(
            name: .fetchAllConfigsTriggerNotification,
            object: nil
        )
    }

}
