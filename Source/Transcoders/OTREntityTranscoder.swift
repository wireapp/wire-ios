//
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

/// HTTP status of a request that's not authorized (client could have been deleted)
private let ClientNotAuthorizedResponseStatus = 403

/// Label error for uploading a message with a client that does not exist
private let UnknownClientLabel = "unknown-client"

/// Label for clients that are missing from the uploaded payload
private let MissingLabel = "missing"

/// Label for clients that were deleted and are still present in the uploaded payload
private let DeletedLabel = "deleted"

/// Error label
private let ErrorLabel = "label"

open class OTREntityTranscoder<Entity : OTREntity> : NSObject, EntityTranscoder {
    
    let context : NSManagedObjectContext
    let clientRegistrationDelegate : ClientRegistrationDelegate
    
    public init(context: NSManagedObjectContext, clientRegistrationDelegate : ClientRegistrationDelegate) {
        self.context = context
        self.clientRegistrationDelegate = clientRegistrationDelegate
    }
    
    open func request(forEntity entity: Entity) -> ZMTransportRequest? {
        return nil
    }
    
    /// If you override this method in your subclass you must call super.
    open func request(forEntity entity: Entity, didCompleteWithResponse response: ZMTransportResponse) {
        _ = handleClientUpdates(fromResponse: response, triggeredByEntity: entity)
    }
    
    /// If you override this method in your subclass you must call super.
    open func shouldTryToResend(entity: Entity, afterFailureWithResponse response: ZMTransportResponse) -> Bool {
        
        if response.result == .permanentError {
            if self.handleDeletedSelfClient(fromResponse: response, clientDeletionDelegate: clientRegistrationDelegate) {
                return false
            }
            
            return handleClientUpdates(fromResponse: response, triggeredByEntity: entity)
        }
        
        return false
    }
    
    private func handleDeletedSelfClient(fromResponse response: ZMTransportResponse, clientDeletionDelegate: ClientRegistrationDelegate) -> Bool {
        // In case the self client got deleted remotely we will receive an event through the push channel and log out.
        // If we for some reason miss the push the BE will repond with a 403 and 'unknown-client' label to our
        // next sending attempt and we will logout and delete the current selfClient then
        if response.httpStatus == ClientNotAuthorizedResponseStatus,
            let payload = response.payload as? [String:AnyObject],
            let label = payload[ErrorLabel] as? String ,
            label == UnknownClientLabel
        {
            clientDeletionDelegate.didDetectCurrentClientDeletion()
            return true
        }
        
        return false
    }
    
    /// Checks if the response for uploading this message contains a list of missing, deleted and reduntant clients
    /// If it does, updated the corresponding clients as needed (add/remove clients)
    /// - returns: whether the request needs to be retried (after missing clients are fetched)
    private func handleClientUpdates(fromResponse response: ZMTransportResponse, triggeredByEntity entity: Entity) -> Bool {
        
        guard let payload = response.payload as? [String:AnyObject] else { return false }
        
        if let deletedMap = payload[DeletedLabel] as? [String:AnyObject] {
            processDeletedClients(deletedMap)
        }
        
        if let missingMap = payload[MissingLabel] as? [String:AnyObject] {
            return processMissingClients(missingMap, forEntity: entity)
        } else {
            return false
        }
        
    }
    
    /// Parses the "missing" clients and creates the corresponding UserClients, then set them as missing
    /// - returns: true if there were any missing clients
    private func processMissingClients(_ missingMap: [String:AnyObject], forEntity entity: Entity) -> Bool {
        
        let allMissingClients = Set(missingMap.flatMap { pair -> [UserClient] in
            
            // user
            guard let userID = UUID(uuidString: pair.0) else { return []}
            let user = ZMUser(remoteID: userID, createIfNeeded: true, in: context)!
            
            // client
            guard let clientIDs = pair.1 as? [String] else { fatal("Missing client ID is not parsed properly") }
            let clients = clientIDs.map { UserClient.fetchUserClient(withRemoteId: $0, forUser: user, createIfNeeded: true)! }
            
            // is this user not there?
            entity.conversation!.checkIfMissingActiveParticipant(user)
            
            return clients
        })
        
        registerNewMissingClients(allMissingClients, forEntity: entity)
        return allMissingClients.count > 0
    }
    
    /// Adds clients to those missing for this entity
    private func registerNewMissingClients(_ missingClients: Set<UserClient>, forEntity entity: Entity) {
        guard missingClients.count > 0 else { return }
        
        let selfClient = ZMUser.selfUser(in: context).selfClient()!
        selfClient.missesClients(missingClients)
        
        if let otrMessage = entity as? ZMOTRMessage {
            selfClient.addNewClientsToIgnored(missingClients, causedBy: otrMessage)
        } else {
            selfClient.addNewClientsToIgnored(missingClients)
        }
    }
    
    /// Parses the "deleted" clients and removes them
    private func processDeletedClients(_ deletedMap: [String:AnyObject]) {
        
        let allDeletedClients = Set(deletedMap.flatMap { pair -> [UserClient] in
            
            // user
            guard let userID = UUID(uuidString: pair.0) else { return [] }
            guard let user = ZMUser(remoteID: userID, createIfNeeded: false, in: context) else { return [] }
            
            // clients
            guard let clientIDs = pair.1 as? [String] else { fatal("Deleted client ID is not parsed properly") }
            let clientIDsSet = Set(clientIDs)
            
            return user.clients.filter {
                guard let remoteIdentifier = $0.remoteIdentifier else { return false }
                return clientIDsSet.contains(remoteIdentifier)
            }
        })
        
        allDeletedClients.forEach {
            $0.deleteClientAndEndSession()
        }
    }
    
}
