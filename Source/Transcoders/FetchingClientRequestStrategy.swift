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
import WireRequestStrategy

private let zmLog = ZMSLog(tag: "fetchClientRS")


public let ZMNeedsToUpdateUserClientsNotificationName = "ZMNeedsToUpdateUserClientsNotification"
public let ZMNeedsToUpdateUserClientsNotificationUserObjectIDKey = "userObjectID"

public extension ZMUser {
    
    func fetchUserClients() {
        NotificationCenter.default.post(
            name: Notification.Name(rawValue: ZMNeedsToUpdateUserClientsNotificationName),
            object: nil,
            userInfo: [ZMNeedsToUpdateUserClientsNotificationUserObjectIDKey: objectID])
    }
}

@objc
public final class FetchingClientRequestStrategy : AbstractRequestStrategy, ZMEventConsumer {

    fileprivate(set) var fetchAllClientsSync: ZMSingleRequestSync! = nil
    
    fileprivate(set) var userClientsObserverToken: NSObjectProtocol!
    fileprivate(set) var userClientsSync: ZMRemoteIdentifierObjectSync!
    
    fileprivate var insertSyncFilter: NSPredicate {
        return NSPredicate { [unowned self] object, _ -> Bool in
            guard let client = object as? UserClient else { return false }
            return client.user == ZMUser.selfUser(in: self.managedObjectContext)
        }
    }
    
    public override init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)
        
        self.configuration = [.allowsRequestsDuringEventProcessing, .allowsRequestsDuringNotificationStreamFetch]
        
        self.userClientsSync = ZMRemoteIdentifierObjectSync(transcoder: self, managedObjectContext: self.managedObjectContext)
        
        self.userClientsObserverToken = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: ZMNeedsToUpdateUserClientsNotificationName), object: nil, queue: .main) { [unowned self] note in
            
            let objectID = note.userInfo?[ZMNeedsToUpdateUserClientsNotificationUserObjectIDKey] as? NSManagedObjectID
            self.managedObjectContext.performGroupedBlock {
                guard let optionalUser = try? objectID.flatMap(self.managedObjectContext.existingObject(with:)), let user = optionalUser as? ZMUser  else { return }
                self.userClientsSync.setRemoteIdentifiersAsNeedingDownload(Set(arrayLiteral: user.remoteIdentifier!))
                RequestAvailableNotification.notifyNewRequestsAvailable(self)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self.userClientsObserverToken)
    }
    
    public override func nextRequestIfAllowed() -> ZMTransportRequest? {
        return userClientsSync.nextRequest()
    }
    
    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        //no-op
    }
}

// Used to fetch clients of particluar user when ui asks for them
extension FetchingClientRequestStrategy: ZMRemoteIdentifierObjectTranscoder {
    
    public func maximumRemoteIdentifiersPerRequest(for sync: ZMRemoteIdentifierObjectSync!) -> UInt {
        return 1
    }
    
    public func request(for sync: ZMRemoteIdentifierObjectSync!, remoteIdentifiers identifiers: Set<UUID>!) -> ZMTransportRequest! {
        
        guard let userId = (identifiers.first as NSUUID?)?.transportString() else { return nil }
        
        //GET /users/<user-id>/clients
        let path = NSString.path(withComponents: ["/users", "\(userId)", "clients"])
        return ZMTransportRequest(path: path, method: .methodGET, payload: nil)
    }
    
    public func didReceive(_ response: ZMTransportResponse!, remoteIdentifierObjectSync sync: ZMRemoteIdentifierObjectSync!, forRemoteIdentifiers remoteIdentifiers: Set<UUID>!) {
        
        guard let identifier = remoteIdentifiers.first,
            let user = ZMUser(remoteID: identifier, createIfNeeded: true, in: managedObjectContext),
            let selfClient = ZMUser.selfUser(in: managedObjectContext).selfClient()
            else { return }
        
        // Create clients from the response
        var newClients = Set<UserClient>()
        guard let arrayPayload = response.payload?.asArray() else { return }
        let clients: [UserClient] = arrayPayload.flatMap {
            guard let dict = $0 as? [String: AnyObject], let identifier = dict["id"] as? String else { return nil }
            guard let client = UserClient.fetchUserClient(withRemoteId: identifier, forUser:user, createIfNeeded: true) else { return nil }
            if client.isInserted {
                newClients.insert(client)
            }
            client.deviceClass = dict["class"] as? String
            return client
        }
        
        // Remove clients that have not been included in the response
        let deletedClients = Set(user.clients).subtracting(Set(clients))
        deletedClients.forEach {
            $0.deleteClientAndEndSession()
        }
        
        // Add clients without a session to missed clients
        newClients.formUnion(clients.filter { !$0.hasSessionWithSelfClient })
        guard newClients.count > 0 else { return }
        selfClient.missesClients(Set(newClients))
        
        // add missing clients to ignored clients
        selfClient.addNewClientsToIgnored(Set(newClients))
    }
}
