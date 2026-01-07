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

import Foundation
import WireLogging

public class ConnectionRequestStrategy: AbstractRequestStrategy, ZMRequestGeneratorSource,
    ZMContextChangeTrackerSource {

    let eventsToProcess: [ZMUpdateEventType] = [
        .userConnection
    ]

    var isFetchingAllConnections: Bool = false
    let connectionByIDSync: IdentifierObjectSync<ConnectionByIDTranscoder>
    let connectionByIDTranscoder: ConnectionByIDTranscoder
    let connectionByQualifiedIDSync: IdentifierObjectSync<ConnectionByQualifiedIDTranscoder>
    let connectionByQualifiedIDTranscoder: ConnectionByQualifiedIDTranscoder
    let localConnectionListSync: PaginatedSync<Payload.PaginatedLocalConnectionList>
    let connectionListSync: PaginatedSync<Payload.PaginatedConnectionList>
    let updateSync: KeyPathObjectSync<ConnectionRequestStrategy>
    let connectToUserActionHandler: ConnectToUserActionHandler
    let updateConnectionActionHandler: UpdateConnectionActionHandler
    let actionSync: EntityActionSync

    private let apiVersion: WireTransport.APIVersion?
    private let isFederationEnabled: Bool

    public init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus,
        apiVersion: WireTransport.APIVersion?,
        localDomain: String?,
        isFederationEnabled: Bool
    ) {

        self.localConnectionListSync =
            PaginatedSync<Payload.PaginatedLocalConnectionList>(
                basePath: "/connections",
                pageSize: 200,
                context: managedObjectContext
            )

        self.connectionListSync =
            PaginatedSync<Payload.PaginatedConnectionList>(
                basePath: "/list-connections",
                pageSize: 200,
                method: .post,
                context: managedObjectContext
            )

        self.connectionByIDTranscoder = ConnectionByIDTranscoder(
            context: managedObjectContext,
            isFederationEnabled: isFederationEnabled
        )
        self.connectionByIDSync = IdentifierObjectSync(
            managedObjectContext: managedObjectContext,
            transcoder: connectionByIDTranscoder
        )
        self.connectionByQualifiedIDTranscoder = ConnectionByQualifiedIDTranscoder(
            context: managedObjectContext,
            isFederationEnabled: isFederationEnabled
        )
        self.connectionByQualifiedIDSync = IdentifierObjectSync(
            managedObjectContext: managedObjectContext,
            transcoder: connectionByQualifiedIDTranscoder
        )

        self.updateSync = KeyPathObjectSync(entityName: ZMConnection.entityName(), \.needsToBeUpdatedFromBackend)

        self.connectToUserActionHandler = ConnectToUserActionHandler(
            context: managedObjectContext,
            localDomain: localDomain,
            isFederationEnabled: isFederationEnabled
        )
        self.updateConnectionActionHandler = UpdateConnectionActionHandler(
            context: managedObjectContext,
            isFederationEnabled: isFederationEnabled
        )
        self.actionSync = EntityActionSync(actionHandlers: [
            connectToUserActionHandler,
            updateConnectionActionHandler
        ])

        self.apiVersion = apiVersion
        self.isFederationEnabled = isFederationEnabled
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        self.configuration = [
            .allowsRequestsWhileOnline
        ]

        updateSync.transcoder = self
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {

        requestGenerators.nextRequest(for: apiVersion)
    }

    public var requestGenerators: [ZMRequestGenerator] {
        [
            connectionByIDSync,
            connectionByQualifiedIDSync,
            actionSync
        ]
    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        [updateSync]
    }

}

extension ConnectionRequestStrategy: KeyPathObjectSyncTranscoder {

    typealias T = ZMConnection

    func synchronize(_ object: ZMConnection, completion: @escaping () -> Void) {
        defer { completion() }
        guard let apiVersion else { return }

        switch apiVersion {
        case .v0:
            if let userID = object.to.remoteIdentifier {
                let userIdSet: Set<ConnectionByIDTranscoder.T> = [userID]
                connectionByIDSync.sync(identifiers: userIdSet)
            }

        case .v1, .v2, .v3, .v4, .v5, .v6, .v7, .v8, .v9, .v10, .v11, .v12, .v13, .v14:
            if let qualifiedID = object.to.qualifiedID {
                let qualifiedIdSet: Set<ConnectionByQualifiedIDTranscoder.T> = [qualifiedID]
                connectionByQualifiedIDSync.sync(identifiers: qualifiedIdSet)
            }
        }
    }

    func cancel(_ object: ZMConnection) {
        // We don't need to cancel connections
    }

}

class ConnectionByIDTranscoder: IdentifierObjectSyncTranscoder {
    public typealias T = UUID

    var fetchLimit: Int = 1

    let context: NSManagedObjectContext
    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder

    private let processor: ConnectionPayloadProcessor

    init(
        context: NSManagedObjectContext,
        isFederationEnabled: Bool
    ) {
        self.context = context
        self.processor = ConnectionPayloadProcessor(isFederationEnabled: isFederationEnabled)
    }

    func request(for identifiers: Set<UUID>, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard let userID = identifiers.first.map({ $0.transportString() }) else { return nil }

        // GET /connections/<UUID>
        return ZMTransportRequest(getFromPath: "/connections/\(userID)", apiVersion: apiVersion.rawValue)
    }

    func didReceive(
        response: ZMTransportResponse,
        for identifiers: Set<UUID>,
        completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }

        guard
            let userID = identifiers.first,
            let connection = ZMConnection.fetch(userID: userID, domain: nil, in: context)
        else {
            WireLogger.eventProcessing.error("Can't update connection since it was found, aborting...")
            return
        }

        guard response.result != .permanentError else {
            connection.needsToBeUpdatedFromBackend = false
            return
        }

        guard
            let rawData = response.rawData,
            let payload = Payload.Connection(rawData, decoder: decoder)
        else {
            Logging.network.warn("Can't process response, aborting.")
            return
        }

        processor.updateOrCreateConnection(
            from: payload,
            in: context
        )
    }

}

class ConnectionByQualifiedIDTranscoder: IdentifierObjectSyncTranscoder {
    public typealias T = QualifiedID

    var fetchLimit: Int = 1

    let context: NSManagedObjectContext
    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder

    private let processor: ConnectionPayloadProcessor

    init(
        context: NSManagedObjectContext,
        isFederationEnabled: Bool
    ) {
        self.context = context
        self.processor = ConnectionPayloadProcessor(isFederationEnabled: isFederationEnabled)
    }

    func request(for identifiers: Set<QualifiedID>, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard
            apiVersion > .v0,
            let qualifiedID = identifiers.first
        else {
            return nil
        }

        // GET /connections/domain/<UUID>
        return ZMTransportRequest(
            getFromPath: "/connections/\(qualifiedID.domain)/\(qualifiedID.uuid.transportString())",
            apiVersion: apiVersion.rawValue
        )
    }

    func didReceive(
        response: ZMTransportResponse,
        for identifiers: Set<QualifiedID>,
        completionHandler: @escaping () -> Void
    ) {
        defer { completionHandler() }

        guard
            let qualifiedID = identifiers.first,
            let connection = ZMConnection.fetch(userID: qualifiedID.uuid, domain: qualifiedID.domain, in: context)
        else {
            WireLogger.eventProcessing.error("Can't update connection since it was found, aborting...")
            return
        }

        guard response.result != .permanentError else {
            connection.needsToBeUpdatedFromBackend = false
            return
        }

        guard
            let rawData = response.rawData,
            let payload = Payload.Connection(rawData, decoder: decoder)
        else {
            Logging.network.error("Can't process response, aborting.")
            return
        }

        processor.updateOrCreateConnection(
            from: payload,
            in: context
        )
    }

}
