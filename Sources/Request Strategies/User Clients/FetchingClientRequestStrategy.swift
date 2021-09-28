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

    fileprivate var userClientsObserverToken: Any? = nil
    fileprivate var userClientsByUserID: IdentifierObjectSync<UserClientByUserIDTranscoder>
    fileprivate var userClientsByUserClientID: IdentifierObjectSync<UserClientByUserClientIDTranscoder>
    fileprivate var userClientsByQualifiedUserID: IdentifierObjectSync<UserClientByQualifiedUserIDTranscoder>
    
    var userClientByUserIDTranscoder: UserClientByUserIDTranscoder
    var userClientByUserClientIDTranscoder: UserClientByUserClientIDTranscoder
    var userClientByQualifiedUserIDTranscoder: UserClientByQualifiedUserIDTranscoder
    
    public override init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        
        self.userClientByUserIDTranscoder = UserClientByUserIDTranscoder(managedObjectContext: managedObjectContext)
        self.userClientByUserClientIDTranscoder = UserClientByUserClientIDTranscoder(managedObjectContext: managedObjectContext)
        self.userClientByQualifiedUserIDTranscoder = UserClientByQualifiedUserIDTranscoder(managedObjectContext: managedObjectContext)
        
        self.userClientsByUserID = IdentifierObjectSync(managedObjectContext: managedObjectContext, transcoder: userClientByUserIDTranscoder)
        self.userClientsByUserClientID = IdentifierObjectSync(managedObjectContext: managedObjectContext, transcoder: userClientByUserClientIDTranscoder)
        self.userClientsByQualifiedUserID = IdentifierObjectSync(managedObjectContext: managedObjectContext, transcoder: userClientByQualifiedUserIDTranscoder)
        
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)
        
        self.configuration = [.allowsRequestsWhileOnline,
                              .allowsRequestsDuringQuickSync,
                              .allowsRequestsWhileWaitingForWebsocket,
                              .allowsRequestsWhileInBackground]
        self.userClientByQualifiedUserIDTranscoder.contextChangedTracker = self
        self.userClientsObserverToken = NotificationInContext.addObserver(name: FetchingClientRequestStrategy.needsToUpdateUserClientsNotificationName,
                                                                          context: self.managedObjectContext.notificationContext,
                                                                          object: nil)
        { [weak self] note in
            guard let `self` = self, let objectID = note.object as? NSManagedObjectID else { return }
            self.managedObjectContext.performGroupedBlock {
                guard let user = (try? self.managedObjectContext.existingObject(with: objectID)) as? ZMUser,
                      let userID = user.remoteIdentifier else { return }


                if let domain = user.domain, self.userClientsByQualifiedUserID.isAvailable {
                    let qualifiedID = Payload.QualifiedID(uuid: userID, domain: domain)
                    self.userClientsByQualifiedUserID.sync(identifiers: [qualifiedID])
                } else {
                    self.userClientsByUserID.sync(identifiers: Set(arrayLiteral: userID))
                }


                RequestAvailableNotification.notifyNewRequestsAvailable(self)
            }
        }
    }
    
    public override func nextRequestIfAllowed() -> ZMTransportRequest? {
        return
            userClientsByUserClientID.nextRequest() ??
            userClientsByUserID.nextRequest() ??
            userClientsByQualifiedUserID.nextRequest()
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
        let initialResult: ([Payload.QualifiedID], [UserClientByUserClientIDTranscoder.UserClientID]) = ([], [])
        let result = userClients.reduce(into: initialResult) { (result, userClient) in

            // We prefer to by qualifiedUserID since can be done in batches and is more efficent, but if the server
            // does not support it we need to fallback to fetching by userClientID
            if userClientsByQualifiedUserID.isAvailable,
               let userID = userClient.user?.remoteIdentifier,
               let domain = userClient.user?.domain {
                result.0.append(Payload.QualifiedID(uuid: userID, domain: domain))
            } else if let userID = userClient.user?.remoteIdentifier,
                      let clientID = userClient.remoteIdentifier {
                result.1.append(UserClientByUserClientIDTranscoder.UserClientID(userId: userID, clientId: clientID))
            }
        }

        userClientsByQualifiedUserID.sync(identifiers: Set(result.0))
        userClientsByUserClientID.sync(identifiers: Set(result.1))
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
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    var isAvailable: Bool {
        return true
    }
    
    var fetchLimit: Int {
        return 1
    }
    
    public func request(for identifiers: Set<UserClientID>) -> ZMTransportRequest? {
        guard let identifier = identifiers.first else { return nil }
        
        //GET /users/<user-id>/clients/<client-id>
        return ZMTransportRequest(path: "/users/\(identifier.userId.transportString())/clients/\(identifier.clientId)", method: .methodGET, payload: nil)
    }
    
    public func didReceive(response: ZMTransportResponse, for identifiers: Set<UserClientID>) {

        guard
            let identifier = identifiers.first,
            let client = UserClient.fetchUserClient(withRemoteId: identifier.clientId,
                                                    forUser: ZMUser.fetchOrCreate(with: identifier.userId,
                                                                                 domain: nil,
                                                                                 in: managedObjectContext),
                                                    createIfNeeded: true)
        else {
            Logging.network.warn("Can't process response, aborting.")
            return
        }
        
        if response.result == .permanentError {
            client.deleteClientAndEndSession()
        } else if let rawData = response.rawData,
                  let payload = Payload.UserClient(rawData, decoder: decoder) {
            payload.update(client)
            let selfClient = ZMUser.selfUser(in: managedObjectContext).selfClient()
            selfClient?.updateSecurityLevelAfterDiscovering(Set(arrayLiteral: client))
        }
    }
}

final class UserClientByQualifiedUserIDTranscoder: IdentifierObjectSyncTranscoder {
                
    public typealias T = Payload.QualifiedID

    weak var contextChangedTracker: ZMContextChangeTracker?
    var managedObjectContext: NSManagedObjectContext
    let decoder: JSONDecoder = .defaultDecoder
    let encoder: JSONEncoder = .defaultEncoder
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    var isAvailable: Bool = true
    
    var fetchLimit: Int {
        return 100
    }
    
    public func request(for identifiers: Set<Payload.QualifiedID>) -> ZMTransportRequest? {

        guard
            let payloadData = identifiers.payloadData(encoder: encoder),
            let payloadAsString = String(bytes: payloadData, encoding: .utf8)
        else {
            return nil
        }
    
        // POST /users/list-clients
        let path = NSString.path(withComponents: ["/users/list-clients"])
        return ZMTransportRequest(path: path, method: .methodPOST, payload: payloadAsString as ZMTransportData?)
    }
    
    public func didReceive(response: ZMTransportResponse, for identifiers: Set<Payload.QualifiedID>) {

        // NOTE should be removed or replaced once the BE exposes a version number.
        guard response.httpStatus != 404 else {
            Logging.network.warn("Endpoint not available, deactivating.")
            isAvailable = false

            // Re-schedule to fetch clients with the clients with the fallback
            if let users = ZMUser.fetchObjects(withRemoteIdentifiers: Set(identifiers.map(\.uuid)),
                                                     in: managedObjectContext) as? Set<ZMUser> {
                users.forEach({ $0.fetchUserClients() })
            }
            return
        }
        
        guard
            let rawData = response.rawData,
            let payload = Payload.UserClientByDomain(rawData, decoder: decoder),
            let selfClient = ZMUser.selfUser(in: managedObjectContext).selfClient()
        else {
            Logging.network.warn("Can't process response, aborting.")
            return
        }

        for (domain, users) in payload {
            for (userID, clientPayloads) in users {
                guard
                    let userID = UUID(uuidString: userID)
                else {
                    continue
                }
                
                let user = ZMUser.fetchOrCreate(with: userID,
                                                domain: domain,
                                                in: managedObjectContext)

                clientPayloads.updateClients(for: user, selfClient: selfClient)
            }
        }
    }
}

final class UserClientByUserIDTranscoder: IdentifierObjectSyncTranscoder {
    
    public typealias T = UUID
    
    var managedObjectContext: NSManagedObjectContext
    let decoder: JSONDecoder = .defaultDecoder
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    var isAvailable: Bool {
        return true
    }
    
    var fetchLimit: Int {
        return 1
    }
    
    public func request(for identifiers: Set<UUID>) -> ZMTransportRequest? {
        guard let userId = identifiers.first?.transportString() else { return nil }
        
        //GET /users/<user-id>/clients
        let path = NSString.path(withComponents: ["/users", "\(userId)", "clients"])
        return ZMTransportRequest(path: path, method: .methodGET, payload: nil)
    }
    
    public func didReceive(response: ZMTransportResponse, for identifiers: Set<UUID>) {

        guard
            let rawData = response.rawData,
            let payload = Payload.UserClients(rawData, decoder: decoder),
            let identifier = identifiers.first,
            let selfClient = ZMUser.selfUser(in: managedObjectContext).selfClient()
        else {
            Logging.network.warn("Can't process response, aborting.")
            return
        }

        let user = ZMUser.fetchOrCreate(with: identifier, domain: nil, in: managedObjectContext)
        payload.updateClients(for: user, selfClient: selfClient)
    }
}
