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

private let zmLog = ZMSLog(tag: "link previews")

public final class LinkPreviewUploadRequestStrategy: AbstractRequestStrategy, ZMContextChangeTrackerSource {

    fileprivate let requestFactory = ClientMessageRequestFactory()

    /// Upstream sync
    fileprivate var upstreamSync: ZMUpstreamModifiedObjectSync!

    public override init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)
        configuration = .allowsRequestsDuringEventProcessing

        upstreamSync = ZMUpstreamModifiedObjectSync(
            transcoder: self,
            entityName: ZMClientMessage.entityName(),
            update: LinkPreviewUploadRequestStrategy.updatePredicate,
            filter: LinkPreviewUploadRequestStrategy.updateFilter,
            keysToSync: [ZMClientMessage.linkPreviewStateKey],
            managedObjectContext: managedObjectContext
        )
    }
    
    static var updatePredicate: NSPredicate {
        return NSPredicate(format: "%K == %d", #keyPath(ZMClientMessage.linkPreviewState), ZMLinkPreviewState.uploaded.rawValue)
    }
    
    static var updateFilter: NSPredicate {
        return NSPredicate { object, _ in
            guard let message = object as? ZMMessage, let sender = message.sender  else { return false }
            
            return sender.isSelfUser
        }
    }

    public var contextChangeTrackers : [ZMContextChangeTracker] {
        return [upstreamSync]
    }

    public override func nextRequestIfAllowed() -> ZMTransportRequest? {
        return upstreamSync.nextRequest()
    }

}


// MAR: - ZMUpstreamTranscoder


extension LinkPreviewUploadRequestStrategy : ZMUpstreamTranscoder {

    public func request(forUpdating managedObject: ZMManagedObject, forKeys keys: Set<String>) -> ZMUpstreamRequest? {
        guard let message = managedObject as? ZMClientMessage else { return nil }
        guard keys.contains(ZMClientMessage.linkPreviewStateKey) else { return nil }
        guard let conversationId = message.conversation?.remoteIdentifier else { return nil }
        requireInternal(true == message.sender?.isSelfUser, "Trying to send message from sender other than self: \(message.nonce?.uuidString ?? "nil nonce")")
        let request = requestFactory.upstreamRequestForMessage(message, forConversationWithId: conversationId)
        zmLog.debug("request to send: \(message.nonce?.uuidString ?? "nil"), linkPreview: \(String(describing: message.genericMessage))")
        return ZMUpstreamRequest(keys: [ZMClientMessage.linkPreviewStateKey], transportRequest: request)
    }
    
    public func dependentObjectNeedingUpdate(beforeProcessingObject dependant: ZMManagedObject) -> Any? {
        guard let message = dependant as? ZMClientMessage, !dependant.isZombieObject else {
            return nil
        }
        return message.dependentObjectNeedingUpdateBeforeProcessing
    }

    public func request(forInserting managedObject: ZMManagedObject, forKeys keys: Set<String>?) -> ZMUpstreamRequest? {
        return nil
    }

    public func shouldProcessUpdatesBeforeInserts() -> Bool {
        return false
    }

    public func shouldRetryToSyncAfterFailed(toUpdate managedObject: ZMManagedObject, request upstreamRequest: ZMUpstreamRequest, response: ZMTransportResponse, keysToParse keys: Set<String>) -> Bool {
        guard let message = managedObject as? ZMClientMessage else { return false }
        return message.parseUploadResponse(response, clientRegistrationDelegate: applicationStatus!.clientRegistrationDelegate).contains(.missing)
    }

    public func objectToRefetchForFailedUpdate(of managedObject: ZMManagedObject) -> ZMManagedObject? {
        return nil
    }

    public func updateUpdatedObject(_ managedObject: ZMManagedObject, requestUserInfo: [AnyHashable: Any]?, response: ZMTransportResponse, keysToParse: Set<String>) -> Bool {
        guard keysToParse.contains(ZMClientMessage.linkPreviewStateKey) else { return false }
        guard let message = managedObject as? ZMClientMessage else { return false }

        // We do not update the message with the response to avoid updating the timestamp.
        message.linkPreviewState = .done
        return false
    }

    public func updateInsertedObject(_ managedObject: ZMManagedObject, request upstreamRequest: ZMUpstreamRequest, response: ZMTransportResponse) {
        // nop
    }
    
}
