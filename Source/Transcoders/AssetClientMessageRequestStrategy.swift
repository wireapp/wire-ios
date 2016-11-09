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
import WireRequestStrategy


public final class AssetClientMessageRequestStrategy: ZMObjectSyncStrategy, RequestStrategy, ZMContextChangeTrackerSource {

    fileprivate let requestFactory = ClientMessageRequestFactory()
    fileprivate weak var clientRegistrationStatus: ClientRegistrationDelegate?
    fileprivate var upstreamSync: ZMUpstreamModifiedObjectSync!

    public init(clientRegistrationStatus: ClientRegistrationDelegate, managedObjectContext: NSManagedObjectContext) {
        self.clientRegistrationStatus = clientRegistrationStatus
        super.init(managedObjectContext: managedObjectContext)

        upstreamSync = ZMUpstreamModifiedObjectSync(
            transcoder: self,
            entityName: ZMAssetClientMessage.entityName(),
            update: ZMAssetClientMessage.v3_messageUpdatePredicate,
            filter: ZMAssetClientMessage.v3_messageInsertionFilter,
            keysToSync: [ZMAssetClientMessageUploadedStateKey],
            managedObjectContext: managedObjectContext
        )
    }

    public func nextRequest() -> ZMTransportRequest? {
        guard let status = clientRegistrationStatus, status.clientIsReadyForRequests else { return nil }
        return upstreamSync.nextRequest()
    }

    public func shouldProcessUpdatesBeforeInserts() -> Bool {
        return false
    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [upstreamSync]
    }

}


// MARK: - ZMUpstreamTranscoder


extension AssetClientMessageRequestStrategy: ZMUpstreamTranscoder {

    public func request(forInserting managedObject: ZMManagedObject, forKeys keys: Set<String>?) -> ZMUpstreamRequest? {
        return nil
    }

    public func updateInsertedObject(_ managedObject: ZMManagedObject, request upstreamRequest: ZMUpstreamRequest, response: ZMTransportResponse) {
        // no-op
    }

    public func request(forUpdating managedObject: ZMManagedObject, forKeys keys: Set<String>) -> ZMUpstreamRequest? {
        guard let message = managedObject as? ZMAssetClientMessage, let conversation = message.conversation else { return nil }
        guard let request = requestFactory.upstreamRequestForMessage(message, forConversationWithId: conversation.remoteIdentifier!) else { fatal("Unable to generate request for \(message)") }
        return ZMUpstreamRequest(keys: [ZMAssetClientMessageUploadedStateKey], transportRequest: request)
    }

    public func updateUpdatedObject(_ managedObject: ZMManagedObject, requestUserInfo: [AnyHashable : Any]? = nil, response: ZMTransportResponse, keysToParse: Set<String>) -> Bool {
        guard let message = managedObject as? ZMAssetClientMessage else { return false }
        if response.result == .success {
            message.delivered = true
            message.markAsSent()
        }
        return false
    }

    public func objectToRefetchForFailedUpdate(of managedObject: ZMManagedObject) -> ZMManagedObject? {
        return nil
    }

}


// MARK: - Predicates


extension ZMAssetClientMessage {

    fileprivate static var v3_messageInsertionFilter: NSPredicate {
        return NSPredicate { (object, _) in
            guard let message = object as? ZMAssetClientMessage else { return false }
            let hasAssetId = message.genericAssetMessage?.assetData?.uploaded.hasAssetId() == true
            let version3 = message.version == 3
            let isImage = message.genericAssetMessage?.v3_isImage == true
            let uploaded = message.transferState == .uploaded && message.uploadState == .done

            return hasAssetId && version3 && isImage && uploaded
        }
    }

    fileprivate static var v3_messageUpdatePredicate: NSPredicate {
        return NSPredicate(format: "delivered == NO && version == 3")
    }
    
}
