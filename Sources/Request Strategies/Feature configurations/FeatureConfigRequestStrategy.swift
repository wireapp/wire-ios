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

    /// Notification to be fired when the feature configuration is changed.
    /// When firing this notification the event has to be included as object in the notification.
    static let featureConfigDidChangeNotification = Notification.Name("featureConfigDidChangeNotification")
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
            let decoder = JSONDecoder()
            let encoder = JSONEncoder()

            switch feature.name {
            case .appLock:
                let config = try decoder.decode(DynamicConfigResponse<Feature.AppLock.Config>.self, from: responseData)
                feature.status = config.status
                feature.config = try encoder.encode(config.config)
            case .fileSharing, .conferenceCalling:
                let config = try decoder.decode(ConfigResponse.self, from: responseData)
                feature.status = config.status
            }

            feature.needsToBeUpdatedFromBackend = false

        } catch {
            zmLog.error("Failed to process feature config response: \(error.localizedDescription)")
        }
    }

    public func delete(_ object: ZMManagedObject!, with response: ZMTransportResponse!, downstreamSync: ZMObjectSync!) {
        // No op
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
            featureService.storeAppLock(.init(configResponse: allConfigs.applock))

        } catch {
            zmLog.error("Failed to decode feature config response: \(error)")
        }
    }
}

//MARK: - ZMEventConsumer

extension FeatureConfigRequestStrategy: ZMEventConsumer {

    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        events.forEach(process)
    }

    private func process(_ event: ZMUpdateEvent) {
        switch event.type {
        case .featureConfigUpdate:
            guard let jsonPayload = try? JSONSerialization.data(withJSONObject: event.payload, options: []),
                  let featurePayload = FeatureUpdateEventPayload(jsonPayload) else {
                return
            }

            Feature.updateOrCreate(havingName: featurePayload.name, in: managedObjectContext) { feature in
                feature.status = featurePayload.status
                feature.config = featurePayload.config
                self.managedObjectContext.saveOrRollback()
                NotificationCenter.default.post(name: .featureConfigDidChangeNotification, object: featurePayload)
            }

        default: break
        }
    }
}

// MARK: - Update event models

public struct FeatureUpdateEventPayload: Decodable {
    public var name: Feature.Name
    public var status: Feature.Status
    public var config: Data?

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let nestedContainer = try container.nestedContainer(keyedBy: ConfigKeys.self, forKey: .data)

        name = try container.decode(Feature.Name.self, forKey: .name)
        status = try nestedContainer.decode(Feature.Status.self, forKey: .status)
        switch name {
        case .appLock:
            config = try nestedContainer.decodeIfPresent(Feature.AppLock.Config.self, forKey: .config).payloadData()
        default:
            return
        }
    }

    enum CodingKeys: String, CodingKey {
        case name
        case data
    }

    enum ConfigKeys: String, CodingKey {
        case status
        case config
    }
}

// MARK: - Response models

private struct AllConfigsResponse: Decodable {

    var applock: DynamicConfigResponse<Feature.AppLock.Config>

}

private struct ConfigResponse: Decodable {

    let status: Feature.Status

}

private struct DynamicConfigResponse<Config: Decodable>: Decodable {

    let status: Feature.Status
    let config: Config

}

private extension Feature.AppLock {

    init(configResponse: DynamicConfigResponse<Config>) {
        self.init(status: configResponse.status, config: configResponse.config)
    }

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
