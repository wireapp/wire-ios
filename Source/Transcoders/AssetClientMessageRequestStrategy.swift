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
        message.update(withPostPayload: response.payload?.asDictionary() ?? [:], updatedKeys: keysToParse)
        _ = message.parseUploadResponse(response, clientDeletionDelegate: clientRegistrationStatus!)

        if response.result == .success {
            if message.fileMessageData?.v3_isImage() == true {
                message.delivered = true
                message.markAsSent()
            } else {
                return updateNonImageFileMessageStatus(for: message)
            }
        }

        return false
    }

    func updateNonImageFileMessageStatus(for message: ZMAssetClientMessage) -> Bool {
        guard let asset = message.genericAssetMessage?.assetData, let filedata = message.fileMessageData else { return false }
        precondition(!filedata.v3_isImage(), "Should not be called with a v3 image message")

        switch message.uploadState {
        case .uploadingPlaceholder: // We uploaded the Asset.original
            if asset.hasPreview() {
                // If the message has a thumbnail we update the state accordingly
                // so the thumbnail can be preprocessed and sent.
                message.uploadState = .uploadingThumbnail
            } else {
                // If we do not have a thumbnail to send we want to send the full asset next.
                message.uploadState = .uploadingFullAsset
            }
            return true
        case .uploadingThumbnail:
            message.uploadState = .uploadingFullAsset
            return true
        case .uploadingFullAsset:
            message.uploadState = .done
            message.transferState = .downloaded
            message.delivered = true
            message.markAsSent()
        default: break
        }

        return false
    }

    public func objectToRefetchForFailedUpdate(of managedObject: ZMManagedObject) -> ZMManagedObject? {
        return nil
    }

    public func shouldRetryToSyncAfterFailed(toUpdate managedObject: ZMManagedObject, request upstreamRequest: ZMUpstreamRequest, response: ZMTransportResponse, keysToParse keys: Set<String>) -> Bool {
        guard let message = managedObject as? ZMAssetClientMessage else { return false }
        var failedBecauseOfMissingClients = false
        if let delegate = self.clientRegistrationStatus {
            failedBecauseOfMissingClients = message.parseUploadResponse(response, clientDeletionDelegate: delegate)
        }
        if !failedBecauseOfMissingClients {
            let shouldUploadFailed = [ZMAssetUploadState.uploadingFullAsset, .uploadingThumbnail].contains(message.uploadState)
            failMessageUpload(message, keys: keys, request: upstreamRequest.transportRequest)
            return shouldUploadFailed
        }

        return failedBecauseOfMissingClients
    }

    fileprivate func failMessageUpload(_ message: ZMAssetClientMessage, keys: Set<String>, request: ZMTransportRequest?) {
        if message.transferState != .cancelledUpload {
            message.transferState = .failedUpload
            message.expire()
        }

        if keys.contains(ZMAssetClientMessageUploadedStateKey) {
            switch message.uploadState {
            case .uploadingPlaceholder:
                deleteRequestData(forMessage: message, includingEncryptedAssetData: true)

            case .uploadingFullAsset, .uploadingThumbnail:
                message.didFailToUploadFileData()
                deleteRequestData(forMessage: message, includingEncryptedAssetData: false)

            case .uploadingFailed: return
            case .done: break
            }

            message.uploadState = .uploadingFailed
        }

        // Tracking
        let messageObjectId = message.objectID
        self.managedObjectContext.zm_userInterface.performGroupedBlock({ () -> Void in
            let uiMessage = try? self.managedObjectContext.zm_userInterface.existingObject(with: messageObjectId)
            let userInfo = [FileUploadRequestStrategyNotification.requestStartTimestampKey: request?.startOfUploadTimestamp != nil ?? Date()]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: FileUploadRequestStrategyNotification.uploadFailedNotificationName), object: uiMessage, userInfo: userInfo)
        })
    }


    // TODO: delete here or after failed upload of the asset as well?

    fileprivate func deleteRequestData(forMessage message: ZMAssetClientMessage, includingEncryptedAssetData: Bool) {
        // delete request data
        message.managedObjectContext?.zm_fileAssetCache.deleteRequestData(message.nonce)

        // delete asset data
        if includingEncryptedAssetData {
            message.managedObjectContext?.zm_fileAssetCache.deleteAssetData(message.nonce, fileName: message.filename!, encrypted: true)
        }
    }

}


// MARK: - Predicates


extension ZMAssetClientMessage {

    fileprivate static var v3_messageInsertionFilter: NSPredicate {
        return NSPredicate { (object, _) in
            guard let message = object as? ZMAssetClientMessage, message.version == 3 else { return false }
            return message.v3_isReadyToUploadOriginal
            || message.v3_isReadyToUploadThumbnail
            || message.v3_isReadyToUploadUploaded
            || message.v3_isReadyToUploadNotUploaded
        }
    }

    private var v3_isReadyToUploadOriginal: Bool {
        let isNoImage = genericAssetMessage?.assetData?.original.hasImage() == false
        let hasOriginal = genericAssetMessage?.assetData?.hasOriginal() == true
        return transferState == .uploading && uploadState == .uploadingPlaceholder && isNoImage && hasOriginal
    }

    private var v3_isReadyToUploadThumbnail: Bool {
        let hasAssetId = genericAssetMessage?.assetData?.preview.remote.hasAssetId() == true
        return transferState == .uploading && uploadState == .uploadingThumbnail && hasAssetId
    }

    private var v3_isReadyToUploadUploaded: Bool {
        let hasAssetId = genericAssetMessage?.assetData?.uploaded.hasAssetId() == true
        return transferState == .uploading && uploadState == .uploadingFullAsset && hasAssetId
    }

    private var v3_isReadyToUploadNotUploaded: Bool {
        let hasNotUploaded = genericAssetMessage?.assetData?.hasNotUploaded() == true
        let failedOrCancelled = transferState == .failedUpload || transferState == .cancelledUpload
        return failedOrCancelled && hasNotUploaded
    }

    fileprivate static var v3_messageUpdatePredicate: NSPredicate {
        return NSPredicate(format: "delivered == NO && version == 3")
    }
    
}
