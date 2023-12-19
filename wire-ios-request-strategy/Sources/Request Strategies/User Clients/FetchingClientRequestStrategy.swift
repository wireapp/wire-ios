// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import WireSystem
import WireTransport
import WireUtilities
import WireCryptobox
import WireDataModel

public let ZMNeedsToUpdateUserClientsNotificationUserObjectIDKey = "userObjectID"

@objc public extension ZMUser {

    func fetchUserClients() {
        NotificationInContext(name: FetchingClientRequestStrategy.needsToUpdateUserClientsNotificationName,
                              context: self.managedObjectContext!.notificationContext,
                              object: self.objectID).post()
    }
}

@objc
public final class FetchingClientRequestStrategy: AbstractRequestStrategy {

    fileprivate static let needsToUpdateUserClientsNotificationName = Notification.Name("ZMNeedsToUpdateUserClientsNotification")

    fileprivate var userClientsObserverToken: Any?
    fileprivate var userClientsByUserID: IdentifierObjectSync<UserClientByUserIDTranscoder>
    fileprivate var userClientsByUserClientID: IdentifierObjectSync<UserClientByUserClientIDTranscoder>
    fileprivate var userClientsByQualifiedUserID: IdentifierObjectSync<UserClientByQualifiedUserIDTranscoder>

    var userClientByUserIDTranscoder: UserClientByUserIDTranscoder
    var userClientByUserClientIDTranscoder: UserClientByUserClientIDTranscoder
    var userClientByQualifiedUserIDTranscoder: UserClientByQualifiedUserIDTranscoder

    private let entitySync: EntityActionSync

    public override init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus) {

        self.userClientByUserIDTranscoder = UserClientByUserIDTranscoder(managedObjectContext: managedObjectContext)
        self.userClientByUserClientIDTranscoder = UserClientByUserClientIDTranscoder(managedObjectContext: managedObjectContext)
        self.userClientByQualifiedUserIDTranscoder = UserClientByQualifiedUserIDTranscoder(managedObjectContext: managedObjectContext)

        self.userClientsByUserID = IdentifierObjectSync(managedObjectContext: managedObjectContext, transcoder: userClientByUserIDTranscoder)
        self.userClientsByUserClientID = IdentifierObjectSync(managedObjectContext: managedObjectContext, transcoder: userClientByUserClientIDTranscoder)
        self.userClientsByQualifiedUserID = IdentifierObjectSync(managedObjectContext: managedObjectContext, transcoder: userClientByQualifiedUserIDTranscoder)

        entitySync = EntityActionSync(actionHandlers: [
            FetchUserClientsActionHandler(context: managedObjectContext)
        ])

        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)

        self.configuration = [.allowsRequestsWhileOnline,
                              .allowsRequestsDuringQuickSync,
                              .allowsRequestsWhileWaitingForWebsocket,
                              .allowsRequestsWhileInBackground]
        self.userClientByQualifiedUserIDTranscoder.contextChangedTracker = self
        self.userClientsObserverToken = NotificationInContext.addObserver(name: FetchingClientRequestStrategy.needsToUpdateUserClientsNotificationName,
                                                                          context: self.managedObjectContext.notificationContext,
                                                                          object: nil) { [weak self] note in
            guard let `self` = self, let objectID = note.object as? NSManagedObjectID else { return }
            self.managedObjectContext.performGroupedBlock {
                guard
                    let apiVersion = BackendInfo.apiVersion,
                    let user = (try? self.managedObjectContext.existingObject(with: objectID)) as? ZMUser,
                    let userID = user.remoteIdentifier
                else {
                    return
                }

                switch apiVersion {
                case .v0:
                    let userIdSet: Set<UserClientByUserIDTranscoder.T> = [userID]
                    self.userClientsByUserID.sync(identifiers: userIdSet)

                case .v1:
                    if let domain = user.domain {
                        let qualifiedID = QualifiedID(uuid: userID, domain: domain)
                        self.userClientsByQualifiedUserID.sync(identifiers: [qualifiedID])
                    } else {
                        let userIdSet: Set<UserClientByUserIDTranscoder.T> = [userID]
                        self.userClientsByUserID.sync(identifiers: userIdSet)
                    }

                case .v2, .v3, .v4, .v5:
                    if let domain = user.domain.nonEmptyValue ?? BackendInfo.domain {
                        let qualifiedID = QualifiedID(uuid: userID, domain: domain)
                        self.userClientsByQualifiedUserID.sync(identifiers: [qualifiedID])
                    }
                }

                RequestAvailableNotification.notifyNewRequestsAvailable(self)
            }
        }
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        // There may exist some clients that need an update, so try to sync any before asking
        // for requests.
        syncClientsNeedingUpdateIfNeeded()

        return
            userClientsByUserClientID.nextRequest(for: apiVersion) ??
            userClientsByUserID.nextRequest(for: apiVersion) ??
            userClientsByQualifiedUserID.nextRequest(for: apiVersion) ??
            entitySync.nextRequest(for: apiVersion)
    }

    private func syncClientsNeedingUpdateIfNeeded() {
        let clients = UserClient.fetchClientsNeedingUpdateFromBackend(in: managedObjectContext)
        fetch(userClients: clients)
    }

}

extension FetchingClientRequestStrategy: ZMContextChangeTracker, ZMContextChangeTrackerSource {

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [self]
    }

    public func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        return UserClient.sortedFetchRequest(with: UserClient.predicateForNeedingToBeUpdatedFromBackend()!)
    }

    public func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        let clientsNeedingToBeUpdated = objects.compactMap({ $0 as? UserClient})

        fetch(userClients: clientsNeedingToBeUpdated)
    }

    public func objectsDidChange(_ object: Set<NSManagedObject>) {
        let clientsNeedingToBeUpdated = object.compactMap({ $0 as? UserClient}).filter(\.needsToBeUpdatedFromBackend)

        fetch(userClients: clientsNeedingToBeUpdated)
    }

    private func fetch(userClients: [UserClient]) {
        guard let apiVersion = BackendInfo.apiVersion else { return }
        let initialResult: ([QualifiedID], [UserClientByUserClientIDTranscoder.UserClientID]) = ([], [])
        let result = userClients.reduce(into: initialResult) { (result, userClient) in
            switch apiVersion {
            case .v0:
                guard let userClientID = userClientID(from: userClient) else { return }
                result.1.append(userClientID)

            case .v1:
                // We prefer to by qualifiedUserID since can be done in batches and is more efficent.
                if let qualifiedID = qualifiedID(from: userClient) {
                    result.0.append(qualifiedID)
                } else if let userClientID = userClientID(from: userClient) {
                    // Fallback.
                    result.1.append(userClientID)
                }
            case .v2, .v3, .v4, .v5:
                if let qualifiedID = qualifiedIDWithFallback(from: userClient) {
                    result.0.append(qualifiedID)
                }
            }
        }

        userClientsByQualifiedUserID.sync(identifiers: Set(result.0))
        userClientsByUserClientID.sync(identifiers: Set(result.1))
    }

    private func userClientID(from userClient: UserClient) -> UserClientByUserClientIDTranscoder.UserClientID? {
        guard
            let userID = userClient.user?.remoteIdentifier,
            let clientID = userClient.remoteIdentifier
        else {
            return nil
        }

        return .init(userId: userID, clientId: clientID)
    }

    private func qualifiedID(from userClient: UserClient) -> QualifiedID? {
        guard
            let userID = userClient.user?.remoteIdentifier,
            let domain = userClient.user?.domain
        else {
            return nil
        }

        return .init(uuid: userID, domain: domain)
    }

    private func qualifiedIDWithFallback(from userClient: UserClient) -> QualifiedID? {
        guard
            let userID = userClient.user?.remoteIdentifier,
            let domain = userClient.user?.domain.nonEmptyValue ?? BackendInfo.domain
        else { return nil }

        return .init(uuid: userID, domain: domain)
    }

}

final class UserClientByUserClientIDTranscoder: IdentifierObjectSyncTranscoder {

    struct UserClientID: Hashable {
        let userId: UUID
        let clientId: String
    }

    public typealias T = UserClientID

    var managedObjectContext: NSManagedObjectContext
    let decoder: JSONDecoder = .defaultDecoder
    private let processor = UserClientPayloadProcessor()

    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    var fetchLimit: Int {
        return 1
    }

    public func request(for identifiers: Set<UserClientID>, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard let identifier = identifiers.first else { return nil }

        let path = "/users/\(identifier.userId.transportString())/clients/\(identifier.clientId)"
        return ZMTransportRequest(path: path, method: .get, payload: nil, apiVersion: apiVersion.rawValue)
    }

    public func didReceive(response: ZMTransportResponse, for identifiers: Set<UserClientID>, completionHandler: @escaping () -> Void) {
        guard
            let identifier = identifiers.first,
            let client = UserClient.fetchUserClient(withRemoteId: identifier.clientId,
                                                    forUser: ZMUser.fetchOrCreate(with: identifier.userId,
                                                                                 domain: nil,
                                                                                 in: managedObjectContext),
                                                    createIfNeeded: true)
        else {
            Logging.network.warn("Can't process response, aborting.")
            return completionHandler()
        }

        if response.result == .permanentError {
            WaitingGroupTask(context: managedObjectContext) { [self] in
                await client.deleteClientAndEndSession()
                await managedObjectContext.perform { completionHandler() }
            }
        } else if let rawData = response.rawData,
                  let payload = Payload.UserClient(rawData, decoder: decoder) {
            processor.updateClient(
                client,
                from: payload
            )

            let selfClient = ZMUser.selfUser(in: managedObjectContext).selfClient()
            let clientSet: Set<UserClient> = [client]
            selfClient?.updateSecurityLevelAfterDiscovering(clientSet)
            completionHandler()
        }
    }
}

final class UserClientByQualifiedUserIDTranscoder: IdentifierObjectSyncTranscoder {

    public typealias T = QualifiedID

    weak var contextChangedTracker: ZMContextChangeTracker?
    var managedObjectContext: NSManagedObjectContext
    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder

    private let processor = UserClientPayloadProcessor()

    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    var fetchLimit: Int {
        return 100
    }

    struct RequestPayload: Codable, Equatable {

        enum CodingKeys: String, CodingKey {

            case qualifiedIDs = "qualified_users"

        }

        let qualifiedIDs: Set<QualifiedID>

    }

    public func request(for identifiers: Set<QualifiedID>, apiVersion: APIVersion) -> ZMTransportRequest? {
        switch apiVersion {
        case .v0:
            Logging.network.warn("fetching user clients by qualified id is not available on API V0.")
            return nil

        case .v1:
            return v1Request(for: identifiers)

        case .v2, .v3, .v4, .v5:
            return v2Request(for: identifiers, apiVersion: apiVersion)
        }
    }

    private func v1Request(for identifiers: Set<QualifiedID>) -> ZMTransportRequest? {
        guard
            let payloadData = RequestPayload(qualifiedIDs: identifiers).payloadData(encoder: encoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            return nil
        }

        return ZMTransportRequest(
            path: "/users/list-clients/v2",
            method: .post,
            payload: payloadAsString as ZMTransportData?,
            apiVersion: 1
        )
    }

    private func v2Request(for identifiers: Set<QualifiedID>, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard
            let payloadData = RequestPayload(qualifiedIDs: identifiers).payloadData(encoder: encoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            return nil
        }

        return ZMTransportRequest(
            path: "/users/list-clients",
            method: .post,
            payload: payloadAsString as ZMTransportData?,
            apiVersion: apiVersion.rawValue
        )
    }

    struct ResponsePayload: Codable {

        enum CodingKeys: String, CodingKey {

            case qualifiedUsers = "qualified_user_map"

        }

        let qualifiedUsers: Payload.UserClientByDomain

    }

    public func didReceive(response: ZMTransportResponse, for identifiers: Set<QualifiedID>, completionHandler: @escaping () -> Void) {
        guard let apiVersion = APIVersion(rawValue: response.apiVersion) else { return }
        switch apiVersion {
        case .v0:
            completionHandler()
            return

        case .v1, .v2, .v3, .v4, .v5:
            WaitingGroupTask(context: managedObjectContext) { [self] in
                await commonResponseHandling(response: response, for: identifiers)
                await managedObjectContext.perform { completionHandler() }
            }
        }
    }

    private func commonResponseHandling(response: ZMTransportResponse, for identifiers: Set<QualifiedID>) async {
        guard
            let rawData = response.rawData,
            let payload = ResponsePayload(rawData, decoder: decoder),
            let selfClient = await managedObjectContext.perform({ ZMUser.selfUser(in: self.managedObjectContext).selfClient() })
        else {
            Logging.network.warn("Can't process response, aborting.")
            await managedObjectContext.perform {
                self.markAllClientsAsUpdated(identifiers: identifiers)
            }
            return
        }

        for (domain, users) in payload.qualifiedUsers {
            for (userID, clientPayloads) in users {
                guard let userID = UUID(uuidString: userID) else {
                    continue
                }

                let user = await managedObjectContext.perform { ZMUser.fetchOrCreate(
                    with: userID,
                    domain: domain,
                    in: self.managedObjectContext
                )}

                await processor.createOrUpdateClients(
                    from: clientPayloads,
                    for: user,
                    selfClient: selfClient
                )
            }
        }

        // We mark all clients as synced, even if they did not appear in
        // the reponse payload, in order to avoid a possible request loop.
        await managedObjectContext.perform {
            self.markAllClientsAsUpdated(identifiers: identifiers)
        }
    }

    private func markAllClientsAsUpdated(identifiers: Set<QualifiedID>) {
        let clients = UserClient.fetchClientsNeedingUpdateFromBackend(in: managedObjectContext)

        for client in clients {
            if let qualifiedID = client.user?.qualifiedID {
                if identifiers.contains(qualifiedID) {
                    client.needsToBeUpdatedFromBackend = false
                }
            }
        }

        managedObjectContext.saveOrRollback()
    }

}

final class UserClientByUserIDTranscoder: IdentifierObjectSyncTranscoder {

    public typealias T = UUID

    var managedObjectContext: NSManagedObjectContext
    let decoder: JSONDecoder = .defaultDecoder

    private let processor = UserClientPayloadProcessor()

    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    var fetchLimit: Int {
        return 1
    }

    public func request(for identifiers: Set<UUID>, apiVersion: APIVersion) -> ZMTransportRequest? {
        guard let userId = identifiers.first?.transportString() else { return nil }

        let path = "/users/\(userId)/clients"
        return ZMTransportRequest(path: path, method: .get, payload: nil, apiVersion: apiVersion.rawValue)
    }

    public func didReceive(response: ZMTransportResponse, for identifiers: Set<UUID>, completionHandler: @escaping () -> Void) {
        guard
            let rawData = response.rawData,
            let payload = Payload.UserClients(rawData, decoder: decoder),
            let identifier = identifiers.first,
            let selfClient = ZMUser.selfUser(in: managedObjectContext).selfClient()
        else {
            Logging.network.warn("Can't process response, aborting.")
            completionHandler()
            return
        }

        let user = ZMUser.fetchOrCreate(
            with: identifier,
            domain: nil,
            in: managedObjectContext
        )

        WaitingGroupTask(context: managedObjectContext) { [self] in
            await processor.createOrUpdateClients(
                from: payload,
                for: user,
                selfClient: selfClient
            )
            await managedObjectContext.perform { completionHandler() }
        }
    }
}
