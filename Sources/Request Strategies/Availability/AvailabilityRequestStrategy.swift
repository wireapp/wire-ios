//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

public class AvailabilityRequestStrategy : AbstractRequestStrategy {
    
    var modifiedSync : ZMUpstreamModifiedObjectSync!
    
    override public init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)
        
        self.modifiedSync = ZMUpstreamModifiedObjectSync(transcoder: self,
                                                         entityName: ZMUser.entityName(),
                                                         update: nil,
                                                         filter: predicateForSelfUserCommunicatingStatus(),
                                                         keysToSync: [AvailabilityKey],
                                                         managedObjectContext: managedObjectContext)
    }
    
    private func predicateForSelfUserCommunicatingStatus() -> NSPredicate {
        let statusPredicate =  NSPredicate { object, _ in
            guard let user = object as? ZMUser else { return false }
            return user.team?.shouldCommunicateStatus ?? true
        }
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [statusPredicate, ZMUser.predicateForSelfUser()])
        
        return compoundPredicate
    }
    
    public override func nextRequestIfAllowed() -> ZMTransportRequest? {
        return modifiedSync.nextRequest()
    }
    
}

extension AvailabilityRequestStrategy : ZMUpstreamTranscoder {
    
    public func request(forUpdating managedObject: ZMManagedObject, forKeys keys: Set<String>) -> ZMUpstreamRequest? {
        guard let selfUser = managedObject as? ZMUser else { return nil }
        
        let originalPath = "/broadcast/otr/messages"
        let message = ZMGenericMessage.message(content: ZMAvailability.availability(selfUser.availability))
        
        guard let dataAndMissingClientStrategy = message.encryptedMessagePayloadDataForBroadcast(context: managedObjectContext) else {
            return nil
        }
        
        let protobufContentType = "application/x-protobuf"
        let path = originalPath.pathWithMissingClientStrategy(strategy: dataAndMissingClientStrategy.strategy)
        let request = ZMTransportRequest(path: path, method: .methodPOST, binaryData: dataAndMissingClientStrategy.data, type: protobufContentType, contentDisposition: nil)
        
        return ZMUpstreamRequest(keys: keys, transportRequest: request)
    }
    
    public func dependentObjectNeedingUpdate(beforeProcessingObject dependant: ZMManagedObject) -> Any? {
        return dependentObjectNeedingUpdateBeforeProcessing
    }
    
    public func updateUpdatedObject(_ managedObject: ZMManagedObject, requestUserInfo: [AnyHashable : Any]? = nil, response: ZMTransportResponse, keysToParse: Set<String>) -> Bool {
        guard let clientRegistrationDelegate = applicationStatus?.clientRegistrationDelegate else { return false }
        
        _ = parseUploadResponse(response, clientRegistrationDelegate: clientRegistrationDelegate)
        
        return false
    }
    
    public func shouldRetryToSyncAfterFailed(toUpdate managedObject: ZMManagedObject, request upstreamRequest: ZMUpstreamRequest, response: ZMTransportResponse, keysToParse keys: Set<String>) -> Bool {
        guard let clientRegistrationDelegate = applicationStatus?.clientRegistrationDelegate else { return false }
        
        return parseUploadResponse(response, clientRegistrationDelegate: clientRegistrationDelegate).contains(.missing)
    }
    
    public func shouldProcessUpdatesBeforeInserts() -> Bool {
        return false
    }
    
    public func request(forInserting managedObject: ZMManagedObject, forKeys keys: Set<String>?) -> ZMUpstreamRequest? {
        return nil // we will never insert objects
    }
    
    public func updateInsertedObject(_ managedObject: ZMManagedObject, request upstreamRequest: ZMUpstreamRequest, response: ZMTransportResponse) {
        // we will never insert objects
    }
    
    public func objectToRefetchForFailedUpdate(of managedObject: ZMManagedObject) -> ZMManagedObject? {
        return nil
    }
    
}

extension AvailabilityRequestStrategy : OTREntity {
    
    public var context: NSManagedObjectContext {
        return managedObjectContext
    }
    
    public func missesRecipients(_ recipients: Set<UserClient>!) {
        // BE notified us about a new client. A session will be established and then we'll try again
    }
    
    public func detectedRedundantClients() {
        // We were sending a message to clients which should not receive it. To recover
        // from this we must restart the slow sync.
        
        applicationStatus?.requestSlowSync()
    }
    
    public func detectedMissingClient(for user: ZMUser) {
        // If we don't know about a user for a missing client we are out sync. To recover
        // from this we must restart the slow sync.
        if !ZMUser.connectionsAndTeamMembers(in: managedObjectContext).contains(user) {
            applicationStatus?.requestSlowSync()
        }
    }
    
    public var dependentObjectNeedingUpdateBeforeProcessing: NSObject? {
        return self.dependentObjectNeedingUpdateBeforeProcessingOTREntity(recipients: ZMUser.connectionsAndTeamMembers(in: managedObjectContext))
    }
    
    public var isExpired: Bool {
        return false
    }
    
    public func expire() {
        // nop
    }
    
}

extension AvailabilityRequestStrategy : ZMContextChangeTrackerSource {
    
    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [modifiedSync]
    }
    
}

extension AvailabilityRequestStrategy : ZMEventConsumer {
    
    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        for event in events {
            guard
                let senderUUID = event.senderUUID(), event.isGenericMessageEvent,
                let message = ZMGenericMessage(from: event), message.hasAvailability()
            else {
                continue
            }
            
            let user = ZMUser(remoteID: senderUUID, createIfNeeded: false, in: managedObjectContext)
            user?.updateAvailability(from: message)
        }
    }
    
}
