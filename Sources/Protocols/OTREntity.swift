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
        if conversation.needsToBeUpdatedFromBackend || conversation.needsToVerifyLegalHold {
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
    
        return dependentObjectNeedingUpdateBeforeProcessingOTREntity(recipients: conversation.activeParticipants)
    }
    
    /// Which objects this message depends on when sending it to a list recipients
    public func dependentObjectNeedingUpdateBeforeProcessingOTREntity(recipients : Set<ZMUser>) -> ZMManagedObject? {
        let recipientClients = recipients.flatMap {
            return Array($0.clients)
        }
        
        // If we discovered a new client we need fetch the client details before retrying
        if let newClient = recipientClients.first(where: { $0.needsToBeUpdatedFromBackend }) {
            return newClient
        }
        
        // If we are missing clients, we need to refetch the clients before retrying
        if let selfClient = ZMUser.selfUser(in: context).selfClient(),
           let missingClients = selfClient.missingClients , missingClients.count > 0
        {
            // Don't block sending of messages if they are not affected by the missing clients
            if !missingClients.intersection(recipientClients).isEmpty {
                
                // make sure that we fetch those clients, even if we somehow gave up on fetching them
                if !(selfClient.modifiedKeys?.contains(ZMUserClientMissingKey) ?? false) {
                    selfClient.setLocallyModifiedKeys(Set(arrayLiteral: ZMUserClientMissingKey))
                    context.enqueueDelayedSave()
                }
                return selfClient
            }
        }
        
        return nil
    }

    public func parseEmptyUploadResponse(_ response: ZMTransportResponse, in conversation: ZMConversation, clientRegistrationDelegate: ClientRegistrationDelegate) -> ZMConversationRemoteClientChangeSet {
        guard !detectedDeletedSelfClient(in: response) else {
            clientRegistrationDelegate.didDetectCurrentClientDeletion()
            return [.deleted]
        }

        // 1) Parse the payload
        guard let payload = response.payload as? [String:AnyObject] else { return [] }
        guard let missingMap = payload[MissingLabel] as? [String: [String]] else { return [] }

        var changes: ZMConversationRemoteClientChangeSet = []
        var allMissingClients: Set<UserClient> = []

        for (userID, remoteClientIdentifiers) in missingMap {
            guard let userID = UUID(uuidString: userID) else { continue }
            let user = ZMUser(remoteID: userID, createIfNeeded: true, in: self.context)!

            let remoteIdentifiers = Set(remoteClientIdentifiers)
            let localIdentifiers = Set(user.clients.compactMap(\.remoteIdentifier))

            // Compute changes
            let deletedClients = localIdentifiers.subtracting(remoteIdentifiers)
            if !deletedClients.isEmpty { changes.insert(.deleted) }

            let missingClients = remoteIdentifiers.subtracting(localIdentifiers)
            if !missingClients.isEmpty { changes.insert(.missing) }

            // Process deletions
            for deletedClientID in deletedClients {
                if let client = UserClient.fetchUserClient(withRemoteId: deletedClientID, forUser: user, createIfNeeded: false) {
                    client.deleteClientAndEndSession()
                }
            }

            // Process missing clients
            let userMissingClients: [UserClient] = missingClients.map {
                let client = UserClient.fetchUserClient(withRemoteId: $0, forUser: user, createIfNeeded: true)!
                client.discoveredByMessage = self as? ZMOTRMessage
                return client
            }

            if !userMissingClients.isEmpty {
                detectedMissingClient(for: user)
                allMissingClients.formUnion(userMissingClients)
            }
        }

        registersNewMissingClients(allMissingClients)
        return changes
    }

    /// Parse the response to an upload, that will inform us of missing, deleted and redundant clients
    public func parseUploadResponse(_ response: ZMTransportResponse, clientRegistrationDelegate: ClientRegistrationDelegate) -> ZMConversationRemoteClientChangeSet {
        guard !detectedDeletedSelfClient(in: response) else {
            clientRegistrationDelegate.didDetectCurrentClientDeletion()
            return [.deleted]
        }

        var changes: ZMConversationRemoteClientChangeSet = []
        
        guard let payload = response.payload as? [String:AnyObject] else { return changes }
        
        if let deletedMap = payload[DeletedLabel] as? [String:AnyObject] {
            if self.processDeletedClients(deletedMap) {
                changes.insert(.deleted)
            }
        }
        
        if let redundantMap = payload[RedundantLabel] as? [String:AnyObject],
            !redundantMap.isEmpty
        {
            changes.insert(.redundant)
            detectedRedundantClients()
        }
        
        if let missingMap = payload[MissingLabel] as? [String:AnyObject] {
            if self.processMissingClients(missingMap) {
                changes.insert(.missing)
            }
        }

        return changes
    }

    private func detectedDeletedSelfClient(in response: ZMTransportResponse) -> Bool {
        // In case the self client got deleted remotely we will receive an event through the push channel and log out.
        // If we for some reason miss the push the BE will repond with a 403 and 'unknown-client' label to our
        // next sending attempt and we will logout and delete the current selfClient then
        if response.httpStatus == ClientNotAuthorizedResponseStatus,
            let payload = response.payload as? [String:AnyObject],
            let label = payload[ErrorLabel] as? String,
            label == UnknownClientLabel {
            return true
        } else {
            return false
        }
    }
    
    /// Parses the "deleted" clients and removes them
    fileprivate func processDeletedClients(_ deletedMap: [String:AnyObject]) -> Bool {
        
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

        guard !allDeletedClients.isEmpty else {
            return false
        }
        
        allDeletedClients.forEach {
            $0.deleteClientAndEndSession()
        }

        return true
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
            let clients: [UserClient] = clientIDs.map {
                let client = UserClient.fetchUserClient(withRemoteId: $0, forUser: user, createIfNeeded: true)!
                client.discoveredByMessage = self as? ZMOTRMessage
                return client
            }
            
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
        
        selfClient.addNewClientsToIgnored(missingClients)
        
    }
    
}
