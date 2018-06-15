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
import WireTransport

private let zmLog = ZMSLog(tag: "Dependencies")

@objc public protocol OTREntity: DependencyEntity {
    
    var context : NSManagedObjectContext { get }
    
    /// Add clients as missing recipients for this entity. If we want to resend
    /// the entity, we need to make sure those missing recipients are fetched
    /// or sending the entity will fail again.
    func missesRecipients(_ recipients: Set<WireDataModel.UserClient>!)
    
    /// if the BE tells us that these users are not in the
    /// conversation anymore, it means that we are out of sync
    /// with the list of participants
    func detectedRedundantClients()
    
    /// This method is called when BE doesn't find clients
    /// in the uploaded payload.
    func detectedMissingClient(for user: ZMUser)
}

/// HTTP status of a request that has
private let ClientNotAuthorizedResponseStatus = 403

/// Label for clients that are missing from the uploaded payload
private let MissingLabel = "missing"

/// Label for clients that were deleted and are still present in the uploaded payload
private let DeletedLabel = "deleted"

/// Label for clients whose user was removed from the conversation but we still think it is in the conversation
private let RedundantLabel = "redundant"

/// Label error for uploading a message with a client that does not exist
private let UnknownClientLabel = "unknown-client"

/// Error label
private let ErrorLabel = "label"

extension OTREntity {
    
    /// Which object this message depends on when sending
    public func dependentObjectNeedingUpdateBeforeProcessingOTREntity(in conversation : ZMConversation) -> ZMManagedObject? {
                
        // If we receive a missing payload that includes users that are not part of the conversation,
        // we need to refetch the conversation before recreating the message payload.
        // Otherwise we end up in an endless loop receiving missing clients error
        if conversation.needsToBeUpdatedFromBackend {
            zmLog.debug("conversation needs to be update from backend")
            return conversation
        }
        
        if (conversation.conversationType == .oneOnOne || conversation.conversationType == .connection)
            && conversation.connection?.needsToBeUpdatedFromBackend == true {
            zmLog.debug("connection needs to be update from backend")
            return conversation.connection
        }
        
        // If the conversation is degraded we shouldn't send the message until the conversation
        // is marked as not secure or it's verified again
        if conversation.securityLevel == .secureWithIgnored {
            zmLog.debug("conversations has security level ignored")
            return conversation
        }
    
        let activeParticipants = conversation.activeParticipants.set as! Set<ZMUser>
        return dependentObjectNeedingUpdateBeforeProcessingOTREntity(recipients: activeParticipants)
    }
    
    /// Which objects this message depends on when sending it to a list recipients
    public func dependentObjectNeedingUpdateBeforeProcessingOTREntity(recipients : Set<ZMUser>) -> ZMManagedObject? {
        // If we are missing clients, we need to refetch the clients before retrying
        if let selfClient = ZMUser.selfUser(in: context).selfClient(),
           let missingClients = selfClient.missingClients , missingClients.count > 0
        {
            let recipientClients = recipients.flatMap {
                return Array($0.clients)
            }
            // Don't block sending of messages if they that are not affected by the missing clients
            if !missingClients.intersection(recipientClients).isEmpty {
                // make sure that we fetch those clients, even if we somehow gave up on fetching them
                selfClient.setLocallyModifiedKeys(Set(arrayLiteral: ZMUserClientMissingKey))
                return selfClient
            }
        }
        
        return nil
    }

    /// Parse the response to an upload, that will inform us of missing, deleted and redundant clients
    public func parseUploadResponse(_ response: ZMTransportResponse, clientRegistrationDelegate: ClientRegistrationDelegate) -> Bool {
        
        // In case the self client got deleted remotely we will receive an event through the push channel and log out.
        // If we for some reason miss the push the BE will repond with a 403 and 'unknown-client' label to our
        // next sending attempt and we will logout and delete the current selfClient then
        if response.httpStatus == ClientNotAuthorizedResponseStatus,
            let payload = response.payload as? [String:AnyObject],
            let label = payload[ErrorLabel] as? String ,
            label == UnknownClientLabel
        {
            clientRegistrationDelegate.didDetectCurrentClientDeletion()
            return false
        }
        
        guard let payload = response.payload as? [String:AnyObject] else { return false }
        
        if let deletedMap = payload[DeletedLabel] as? [String:AnyObject] {
            self.processDeletedClients(deletedMap)
        }
        
        if let redundantMap = payload[RedundantLabel] as? [String:AnyObject],
            !redundantMap.isEmpty
        {
            detectedRedundantClients()
        }
        
        if let missingMap = payload[MissingLabel] as? [String:AnyObject] {
            return self.processMissingClients(missingMap)
        } else {
            return false
        }
    }
    
    /// Parses the "deleted" clients and removes them
    fileprivate func processDeletedClients(_ deletedMap: [String:AnyObject]) {
        
        let allDeletedClients = Set(deletedMap.flatMap { pair -> [UserClient] in
            
            // user
            guard let userID = UUID(uuidString: pair.0) else { return [] }
            guard let user = ZMUser(remoteID: userID, createIfNeeded: false, in: self.context) else { return [] }
            
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
    
    /// Parses the "missing" clients and creates the corresponding UserClients, then set them as missing
    /// - returns: true if there were any missing clients
    fileprivate func processMissingClients(_ missingMap: [String:AnyObject]) -> Bool {
        
        let allMissingClients = Set(missingMap.flatMap { pair -> [UserClient] in
            
            // user
            guard let userID = UUID(uuidString: pair.0) else { return [] }
            let user = ZMUser(remoteID: userID, createIfNeeded: true, in: self.context)!
            
            // client
            guard let clientIDs = pair.1 as? [String] else { fatal("Missing client ID is not parsed properly") }
            let clients = clientIDs.map { UserClient.fetchUserClient(withRemoteId: $0, forUser: user, createIfNeeded: true)! }
            
            // is this user not there?
            detectedMissingClient(for: user)
            
            return clients
        })
        
        self.registersNewMissingClients(allMissingClients)
        return allMissingClients.count > 0
    }
    
    /// Adds clients to those missing for this message
    fileprivate func registersNewMissingClients(_ missingClients: Set<UserClient>) {
        guard missingClients.count > 0 else { return }
        
        let selfClient = ZMUser.selfUser(in: self.context).selfClient()!
        selfClient.missesClients(missingClients)
        self.missesRecipients(missingClients)
        
        selfClient.addNewClientsToIgnored(missingClients, causedBy: self as? ZMOTRMessage)
        
    }
    
}
