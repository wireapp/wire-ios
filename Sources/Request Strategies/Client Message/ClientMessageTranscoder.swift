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

fileprivate let zmLog = ZMSLog(tag: "Network")

/// Creates network requests to send client messages,
/// and parses received client messages
public class ClientMessageTranscoder: AbstractRequestStrategy {

    
    fileprivate let requestFactory: ClientMessageRequestFactory
    private(set) fileprivate var upstreamObjectSync: ZMUpstreamInsertedObjectSync!
    fileprivate let messageExpirationTimer: MessageExpirationTimer
    fileprivate weak var localNotificationDispatcher: PushMessageHandler!
    
    public init(in moc:NSManagedObjectContext,
         localNotificationDispatcher: PushMessageHandler,
         applicationStatus: ApplicationStatus)
    {
        self.localNotificationDispatcher = localNotificationDispatcher
        self.requestFactory = ClientMessageRequestFactory()
        self.messageExpirationTimer = MessageExpirationTimer(moc: moc, entityNames: [ZMClientMessage.entityName(), ZMAssetClientMessage.entityName()], localNotificationDispatcher: localNotificationDispatcher)
        
        super.init(withManagedObjectContext: moc, applicationStatus: applicationStatus)
        
        self.configuration = [.allowsRequestsDuringEventProcessing, .allowsRequestsWhileInBackground]
        self.upstreamObjectSync = ZMUpstreamInsertedObjectSync(transcoder: self, entityName: ZMClientMessage.entityName(), filter: ClientMessageTranscoder.insertFilter, managedObjectContext: moc)
        self.deleteOldEphemeralMessages()
    }
    
    deinit {
        self.messageExpirationTimer.tearDown()
    }
    
    public override func nextRequestIfAllowed() -> ZMTransportRequest? {
        return self.upstreamObjectSync.nextRequest()
    }
    
    static var insertFilter: NSPredicate {
        return NSPredicate { object, _ in
            guard let message = object as? ZMMessage, let sender = message.sender  else { return false }
            
            return sender.isSelfUser
        }
    }
}

extension ClientMessageTranscoder: ZMContextChangeTrackerSource {
    
    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [self.upstreamObjectSync, self.messageExpirationTimer]
    }
}

extension ClientMessageTranscoder: ZMUpstreamTranscoder {
    
    public func shouldProcessUpdatesBeforeInserts() -> Bool {
        return false
    }
    
    public func request(forUpdating managedObject: ZMManagedObject, forKeys keys: Set<String>) -> ZMUpstreamRequest? {
        return nil
    }
    
    public func request(forInserting managedObject: ZMManagedObject, forKeys keys: Set<String>?) -> ZMUpstreamRequest? {
        
        guard let message = managedObject as? ZMClientMessage,
            !message.isExpired else {
                zmLog.info("Cannot create request: message = \(managedObject) message.isExpired = \((managedObject as? ZMClientMessage)?.isExpired ?? false)")
                return nil
        }
        
        requireInternal(true == message.sender?.isSelfUser, "Trying to send message from sender other than self: \(message.nonce?.uuidString ?? "nil nonce")")

        if message.conversation?.conversationType == .oneOnOne {
            // Update expectsReadReceipt flag to reflect the current user setting
            if let updatedGenericMessage = message.genericMessage?.setExpectsReadConfirmation(ZMUser.selfUser(in: managedObjectContext).readReceiptsEnabled) {
                message.add(updatedGenericMessage.data())
            }
        }
        
        let request = self.requestFactory.upstreamRequestForMessage(message, forConversationWithId: message.conversation!.remoteIdentifier!)!
        
        // We need to flush the encrypted payloads cache, since the client is online now (request succeeded).
        let completionHandler = ZMCompletionHandler(on: self.managedObjectContext) { response in
            guard let selfClient = ZMUser.selfUser(in: self.managedObjectContext).selfClient(),
                    response.result == .success else {
                return
            }
            selfClient.keysStore.encryptionContext.perform { (session) in
                session.purgeEncryptedPayloadCache()
            }
        }
        
        request.add(completionHandler)
        
        if message.genericMessage?.hasConfirmation() == true && self.applicationStatus!.deliveryConfirmation.needsToSyncMessages {
            request.forceToVoipSession()
        }
        
        self.messageExpirationTimer.stop(for: message)
        if let expiration = message.expirationDate {
            request.expire(at: expiration)
        }
        return ZMUpstreamRequest(keys: keys, transportRequest: request)
    }
    
    public func requestExpired(for managedObject: ZMManagedObject, forKeys keys: Set<String>) {
        guard let message = managedObject as? ZMOTRMessage else { return }
        message.expire()
        self.localNotificationDispatcher.didFailToSend(message)
    }
    
    public func objectToRefetchForFailedUpdate(of managedObject: ZMManagedObject) -> ZMManagedObject? {
        guard let message = managedObject as? ZMOTRMessage else { return nil }
        return message.conversation
    }
}

extension ClientMessageTranscoder {

    public var hasPendingMessages: Bool {
        return self.messageExpirationTimer.hasMessageTimersRunning || self.upstreamObjectSync.hasCurrentlyRunningRequests;
    }
    
    func insertMessage(from event: ZMUpdateEvent, prefetchResult: ZMFetchRequestBatchResult?) {
        switch event.type {
        case .conversationClientMessageAdd, .conversationOtrMessageAdd, .conversationOtrAssetAdd:
            
            // process generic message first, b/c if there is no updateResult, then
            // a the event from a deleted message wouldn't delete the notification.
            if event.source == .pushNotification || event.source == .webSocket {
                if let genericMessage = ZMGenericMessage(from: event) {
                    self.localNotificationDispatcher.process(genericMessage)
                }
            }
            
            guard let updateResult = ZMOTRMessage.messageUpdateResult(from: event, in: self.managedObjectContext, prefetchResult: prefetchResult) else {
                return
            }
            
            updateResult.message?.markAsSent()
                        
            if type(of: self.applicationStatus!.deliveryConfirmation).sendDeliveryReceipts {
                if updateResult.needsConfirmation {
                    let confirmation = updateResult.message!.confirmDelivery()!
                    if event.source == .pushNotification {
                        self.applicationStatus!.deliveryConfirmation.needsToConfirmMessage(confirmation.nonce!)
                    }
                }
            }
            
            if let updateMessage = updateResult.message, event.source == .pushNotification || event.source == .webSocket {
                self.localNotificationDispatcher.process(updateMessage)
            }
            
        default:
            break
        }
    }
    
    fileprivate func deleteOldEphemeralMessages() {
        self.managedObjectContext.performGroupedBlock { [weak self] in
            guard let `self` = self else { return }
            ZMMessage.deleteOldEphemeralMessages(self.managedObjectContext)
            self.managedObjectContext.saveOrRollback()
        }
    }

    public func updateInsertedObject(_ managedObject: ZMManagedObject, request upstreamRequest: ZMUpstreamRequest, response: ZMTransportResponse) {
        
        guard let message = managedObject as? ZMClientMessage,
            !managedObject.isZombieObject,
            let genericMessage = message.genericMessage else {
                return
        }
        
        self.update(message, from: response, keys: upstreamRequest.keys ?? Set())
        _ = message.parseMissingClientsResponse(response, clientRegistrationDelegate: self.applicationStatus!.clientRegistrationDelegate)
        
        if genericMessage.hasReaction() {
            message.managedObjectContext?.delete(message)
        }
        if genericMessage.hasConfirmation() {
            self.applicationStatus?.deliveryConfirmation.didConfirmMessage(message.nonce!)
            message.managedObjectContext?.delete(message)
        }
    }
    
    private func update(_ message: ZMClientMessage, from response: ZMTransportResponse, keys: Set<String>) {
        guard !message.isZombieObject else {
            return
        }
        
        self.messageExpirationTimer.stop(for: message)
        message.removeExpirationDate()
        message.markAsSent()
        message.update(withPostPayload: response.payload?.asDictionary() ?? [:], updatedKeys: keys)
        _ = message.parseMissingClientsResponse(response, clientRegistrationDelegate: self.applicationStatus!.clientRegistrationDelegate)

    }

    public func updateUpdatedObject(_ managedObject: ZMManagedObject, requestUserInfo: [AnyHashable : Any]? = nil, response: ZMTransportResponse, keysToParse: Set<String>) -> Bool {
        guard let message = managedObject as? ZMClientMessage,
            !managedObject.isZombieObject else {
                return false
        }
        self.update(message, from: response, keys: keysToParse)
        _ = message.parseMissingClientsResponse(response, clientRegistrationDelegate: self.applicationStatus!.clientRegistrationDelegate)
        return false
    }

    public func shouldRetryToSyncAfterFailed(toUpdate managedObject: ZMManagedObject, request upstreamRequest: ZMUpstreamRequest, response: ZMTransportResponse, keysToParse keys: Set<String>) -> Bool {
        guard let message = managedObject as? ZMOTRMessage,
            !managedObject.isZombieObject else {
                return false
        }
        return message.parseMissingClientsResponse(response, clientRegistrationDelegate: self.applicationStatus!.clientRegistrationDelegate)
    }
    
    public func shouldCreateRequest(toSyncObject managedObject: ZMManagedObject, forKeys keys: Set<String>, withSync sync: Any) -> Bool {
        guard let message = managedObject as? ZMClientMessage,
            !managedObject.isZombieObject,
            let genericMessage = message.genericMessage else { return false }
        if genericMessage.hasConfirmation() == true {
            let messageNonce = UUID(uuidString: genericMessage.confirmation.firstMessageId)
            let sentMessage = ZMMessage.fetch(withNonce: messageNonce, for: message.conversation!, in: message.managedObjectContext!)
            return (sentMessage?.sender != nil)
                || (message.conversation?.connectedUser != nil)
                || (message.conversation?.lastServerSyncedActiveParticipants.count > 0)
        }
        return true
    }
    
    public func dependentObjectNeedingUpdate(beforeProcessingObject dependant: ZMManagedObject) -> Any? {
        guard let message = dependant as? ZMClientMessage, !dependant.isZombieObject else {
            return nil
        }
        
        return message.dependentObjectNeedingUpdateBeforeProcessing
    }
}

// MARK: - Update events
extension ClientMessageTranscoder : ZMEventConsumer {
    
    public func processEvents(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?) {
        events.forEach { _ = self.insertMessage(from: $0, prefetchResult: prefetchResult) }
    }    
    
    public func messageNoncesToPrefetch(toProcessEvents events: [ZMUpdateEvent]) -> Set<UUID> {
        return Set(events.compactMap {
            switch $0.type {
            case .conversationClientMessageAdd, .conversationOtrMessageAdd, .conversationOtrAssetAdd:
                return $0.messageNonce()
            default:
                return nil
            }
        })
    }
    
    private func nonces(for updateEvents: [ZMUpdateEvent]) -> [UpdateEventWithNonce] {
        return updateEvents.compactMap {
            switch $0.type {
            case .conversationClientMessageAdd, .conversationOtrMessageAdd, .conversationOtrAssetAdd:
                if let nonce = $0.messageNonce() {
                    return UpdateEventWithNonce(event: $0, nonce: nonce)
                }
                return nil
            default:
                return nil
            }
        }
    }
}

// MARK: - Helpers
private struct UpdateEventWithNonce {
    let event: ZMUpdateEvent
    let nonce: UUID
}
