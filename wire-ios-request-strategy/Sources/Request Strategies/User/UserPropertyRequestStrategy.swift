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

import Foundation
import WireTransport

// MARK: - UserProperty

private enum UserProperty: CaseIterable {
    case readReceiptsEnabled
}

extension UserProperty {
    static let propertiesPath = "properties"

    var propertyName: String {
        switch self {
        case .readReceiptsEnabled:
            "readReceiptsEnabled"
        }
    }

    var serverName: String {
        switch self {
        case .readReceiptsEnabled:
            "WIRE_RECEIPT_MODE"
        }
    }

    init?(serverName: String) {
        let matchingProperty = UserProperty.allCases.first { $0.serverName == serverName }
        guard let property = matchingProperty else {
            return nil
        }
        self = property
    }

    init?(propertyName: String) {
        let matchingProperty = UserProperty.allCases.first { $0.propertyName == propertyName }
        guard let property = matchingProperty else {
            return nil
        }
        self = property
    }

    func upstreamRequest(newValue: ZMTransportData, apiVersion: APIVersion) -> ZMTransportRequest {
        let path = [UserProperty.propertiesPath, serverName].joined(separator: "/")
        return ZMTransportRequest(path: path, method: .put, payload: newValue, apiVersion: apiVersion.rawValue)
    }

    func downstreamRequest(apiVersion: APIVersion) -> ZMTransportRequest {
        let path = [UserProperty.propertiesPath, serverName].joined(separator: "/")
        return ZMTransportRequest(getFromPath: path, apiVersion: apiVersion.rawValue)
    }

    typealias  UpdateType = (source: UpdateSource, method: UpdateMethod)

    enum UpdateSource {
        case slowSync
        case notificationStream
    }

    enum UpdateMethod {
        case set
        case delete

        // MARK: Lifecycle

        init(eventType: ZMUpdateEventType) {
            switch eventType {
            case .userPropertiesSet:
                self = .set
            case .userPropertiesDelete:
                self = .delete
            default:
                fatal("Incompatible event type: \(eventType)")
            }
        }
    }

    func parseUpdate(for selfUser: ZMUser, updateType: UpdateType, payload value: Any?) {
        switch (self, updateType.method) {
        case (.readReceiptsEnabled, .set):
            let intValue: Int
            if let numberValue = value as? Int {
                intValue = numberValue
            } else if let stringValue = value as? String,
                      let numberValue = Int(stringValue) {
                intValue = numberValue
            } else {
                return
            }

            selfUser.readReceiptsEnabled = intValue > 0
            if updateType.source == .notificationStream {
                selfUser.readReceiptsEnabledChangedRemotely = true
            }

        case (.readReceiptsEnabled, .delete):
            selfUser.readReceiptsEnabled = false
            if updateType.source == .notificationStream {
                selfUser.readReceiptsEnabledChangedRemotely = true
            }
        }
    }

    func transportValue(for selfUser: ZMUser) -> ZMTransportData {
        switch self {
        case .readReceiptsEnabled:
            (selfUser.readReceiptsEnabled ? "1" : "0") as ZMTransportData
        }
    }
}

// MARK: - UserPropertyRequestStrategy

public class UserPropertyRequestStrategy: AbstractRequestStrategy {
    // MARK: Lifecycle

    override public init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus
    ) {
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        let allProperties = UserProperty.allCases.map(\.propertyName)

        if ZMUser.selfUser(in: managedObjectContext).needsPropertiesUpdate {
            initializePropertiesToFetch()
        }

        self.modifiedSync = ZMUpstreamModifiedObjectSync(
            transcoder: self,
            entityName: ZMUser.entityName(),
            update: nil,
            filter: ZMUser.predicateForSelfUser(),
            keysToSync: allProperties,
            managedObjectContext: managedObjectContext
        )

        self.downstreamSync = ZMSingleRequestSync(
            singleRequestTranscoder: self,
            groupQueue: managedObjectContext
        )
    }

    // MARK: Public

    override public func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        if ZMUser.selfUser(in: managedObjectContext).needsPropertiesUpdate {
            downstreamSync.readyForNextRequestIfNotBusy()
            return downstreamSync.nextRequest(for: apiVersion)
        } else {
            return modifiedSync.nextRequest(for: apiVersion)
        }
    }

    // MARK: Internal

    var modifiedSync: ZMUpstreamModifiedObjectSync!
    var downstreamSync: ZMSingleRequestSync!

    // MARK: Fileprivate

    fileprivate var propertiesToFetch: Set<UserProperty> = Set()
    fileprivate var fetchedProperty: UserProperty?
}

// MARK: ZMUpstreamTranscoder

extension UserPropertyRequestStrategy: ZMUpstreamTranscoder {
    public func request(
        forUpdating managedObject: ZMManagedObject,
        forKeys keys: Set<String>,
        apiVersion: APIVersion
    ) -> ZMUpstreamRequest? {
        guard let selfUser = managedObject as? ZMUser else {
            return nil
        }

        let allProperties = Set(UserProperty.allCases.map(\.propertyName))

        let intersect = allProperties.intersection(keys)

        guard let first = intersect.first,
              let property = UserProperty(propertyName: first) else {
            return nil
        }

        let request: ZMTransportRequest = switch property {
        case .readReceiptsEnabled:
            property.upstreamRequest(newValue: property.transportValue(for: selfUser), apiVersion: apiVersion)
        }

        return ZMUpstreamRequest(keys: keys, transportRequest: request)
    }

    public func dependentObjectNeedingUpdate(beforeProcessingObject dependant: ZMManagedObject) -> Any? {
        nil
    }

    public func updateUpdatedObject(
        _ managedObject: ZMManagedObject,
        requestUserInfo: [AnyHashable: Any]? = nil,
        response: ZMTransportResponse,
        keysToParse: Set<String>
    ) -> Bool {
        false
    }

    public func shouldRetryToSyncAfterFailed(
        toUpdate managedObject: ZMManagedObject,
        request upstreamRequest: ZMUpstreamRequest,
        response: ZMTransportResponse,
        keysToParse keys: Set<String>
    ) -> Bool {
        false
    }

    public func shouldProcessUpdatesBeforeInserts() -> Bool {
        false
    }

    public func request(
        forInserting managedObject: ZMManagedObject,
        forKeys keys: Set<String>?,
        apiVersion: APIVersion
    ) -> ZMUpstreamRequest? {
        nil // we will never insert objects
    }

    public func updateInsertedObject(
        _ managedObject: ZMManagedObject,
        request upstreamRequest: ZMUpstreamRequest,
        response: ZMTransportResponse
    ) {
        // we will never insert objects
    }

    public func objectToRefetchForFailedUpdate(of managedObject: ZMManagedObject) -> ZMManagedObject? {
        nil
    }
}

// MARK: ZMContextChangeTrackerSource

extension UserPropertyRequestStrategy: ZMContextChangeTrackerSource {
    public var contextChangeTrackers: [ZMContextChangeTracker] {
        [modifiedSync]
    }
}

// MARK: ZMEventConsumer

extension UserPropertyRequestStrategy: ZMEventConsumer {
    static let UpdateEventKey = "key"
    static let UpdateEventValue = "value"

    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        for event in events {
            guard event.type.isOne(of: [ZMUpdateEventType.userPropertiesSet, ZMUpdateEventType.userPropertiesDelete]),
                  let keyChanged = event.payload[UserPropertyRequestStrategy.UpdateEventKey] as? String,
                  let property = UserProperty(serverName: keyChanged) else {
                continue
            }

            let value = event.payload[UserPropertyRequestStrategy.UpdateEventValue]

            property.parseUpdate(
                for: ZMUser.selfUser(in: managedObjectContext),
                updateType: (.notificationStream, .init(eventType: event.type)),
                payload: value
            )
        }
    }
}

// MARK: ZMSingleRequestTranscoder

extension UserPropertyRequestStrategy: ZMSingleRequestTranscoder {
    fileprivate func initializePropertiesToFetch() {
        propertiesToFetch = Set(UserProperty.allCases)
    }

    fileprivate func nextProperty() -> UserProperty? {
        fetchedProperty = propertiesToFetch.removeFirst()
        return fetchedProperty
    }

    public func request(for sync: ZMSingleRequestSync, apiVersion: APIVersion) -> ZMTransportRequest? {
        if propertiesToFetch.isEmpty {
            initializePropertiesToFetch()
        }

        guard let property = nextProperty() else {
            return nil
        }

        return property.downstreamRequest(apiVersion: apiVersion)
    }

    public func didReceive(_ response: ZMTransportResponse, forSingleRequest sync: ZMSingleRequestSync) {
        // No more properties left: the sync is done.
        if propertiesToFetch.isEmpty {
            ZMUser.selfUser(in: managedObjectContext).needsPropertiesUpdate = false
        }

        guard let property = fetchedProperty else {
            return
        }

        if response.result == .permanentError {
            property.parseUpdate(
                for: ZMUser.selfUser(in: managedObjectContext),
                updateType: (.slowSync, .delete),
                payload: nil
            )
        } else if response.result == .success, let payload = response.payload {
            property.parseUpdate(
                for: ZMUser.selfUser(in: managedObjectContext),
                updateType: (.slowSync, .set),
                payload: payload
            )
        }
    }
}
