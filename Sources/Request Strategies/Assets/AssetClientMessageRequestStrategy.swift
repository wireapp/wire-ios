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

/// The `AssetClientMessageRequestStrategy` for creating requests to insert the genericMessage of a `ZMAssetClientMessage`
/// remotely. This is only necessary for the `/assets/v3' endpoint as we upload the asset, receive the asset ID in the response,
/// manually add it to the genericMessage and send it using the `/otr/messages` endpoint like any other message.
/// This is an additional step required as the fan-out was previously done by the backend when uploading a v2 asset.
/// There are mutliple occasions where we might want to send the genericMessage of a `ZMAssetClientMessage` again:
///
/// * We just inserted the message and want to upload the `Asset.Original` containing the metadata about the asset.
/// * (Optional) If the asset has data that can be used to show a preview of it, we want to upload the `Asset.Preview` as soon as the preview data has been preprocessed and uploaded using the `/assets/v3` endpoint.
/// * When the actual asset data has been preprocessed (encrypted) and uploaded we want to insert the `Asset.Uploaded` message.
/// * If we fail to upload the preview or uploaded message we will upload an `Asset.NOTUploaded` genericMessage.
public final class AssetClientMessageRequestStrategy: AbstractRequestStrategy, ZMContextChangeTrackerSource {

    fileprivate let requestFactory = ClientMessageRequestFactory()
    fileprivate var upstreamSync: ZMUpstreamModifiedObjectSync!
    fileprivate var assetAnalytics: AssetAnalytics

    public override init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        assetAnalytics = AssetAnalytics(managedObjectContext: managedObjectContext)
        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)
        configuration = .allowsRequestsDuringEventProcessing

        upstreamSync = ZMUpstreamModifiedObjectSync(
            transcoder: self,
            entityName: ZMAssetClientMessage.entityName(),
            update: ZMAssetClientMessage.v3_messageUpdatePredicate,
            filter: ZMAssetClientMessage.v3_messageInsertionFilter,
            keysToSync: [#keyPath(ZMAssetClientMessage.uploadState)],
            managedObjectContext: managedObjectContext
        )
    }

    public override func nextRequestIfAllowed() -> ZMTransportRequest? {
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

    public func dependentObjectNeedingUpdate(beforeProcessingObject dependant: ZMManagedObject) -> Any? {
        return (dependant as? ZMMessage)?.dependentObjectNeedingUpdateBeforeProcessing
    }

    public func request(forUpdating managedObject: ZMManagedObject, forKeys keys: Set<String>) -> ZMUpstreamRequest? {
        guard let message = managedObject as? ZMAssetClientMessage, let conversation = message.conversation else { return nil }
        guard let request = requestFactory.upstreamRequestForMessage(message, forConversationWithId: conversation.remoteIdentifier!) else { fatal("Unable to generate request for \(message.privateDescription)") }
        requireInternal(true == message.sender?.isSelfUser, "Trying to send message from sender other than self: \(message.nonce?.uuidString ?? "nil nonce")")
        return ZMUpstreamRequest(keys: [#keyPath(ZMAssetClientMessage.uploadState)], transportRequest: request)
    }

    public func updateUpdatedObject(_ managedObject: ZMManagedObject, requestUserInfo: [AnyHashable : Any]? = nil, response: ZMTransportResponse, keysToParse: Set<String>) -> Bool {
        guard let message = managedObject as? ZMAssetClientMessage else { return false }
        message.update(withPostPayload: response.payload?.asDictionary() ?? [:], updatedKeys: keysToParse)
        if let delegate = applicationStatus?.clientRegistrationDelegate{
            _ = message.parseUploadResponse(response, clientRegistrationDelegate: delegate)
        }

        if response.result == .success {
            if message.fileMessageData?.v3_isImage == true {
                message.delivered = true
                message.uploadState = .done
                message.markAsSent()
            } else {
                return updateNonImageFileMessageStatus(for: message, response: response)
            }
        }

        return false
    }

    func updateNonImageFileMessageStatus(for message: ZMAssetClientMessage, response: ZMTransportResponse) -> Bool {
        guard let filedata = message.fileMessageData else { return false }
        precondition(!filedata.v3_isImage, "Should not be called with a v3 image message")

        switch message.uploadState {
        case .uploadingPlaceholder: // We uploaded the Asset.original
            if nil != message.fileMessageData?.previewData {
                // If the message has a thumbnail we update the state accordingly
                // so the thumbnail can be preprocessed and sent.
                message.uploadState = .uploadingThumbnail
            } else {
                // If we do not have a thumbnail to send we want to send the full asset next.
                message.uploadState = .uploadingFullAsset
            }

            return true
        case .uploadingThumbnail: // We uploaded the Asset.preview
            message.uploadState = .uploadingFullAsset
            return true
        case .uploadingFullAsset: // We uploaded the Asset.uploaded
            message.uploadState = .done
            message.transferState = .downloaded
            message.delivered = true
            message.markAsSent()

            // Track successful fileupload
            assetAnalytics.trackUploadFinished(for: message, with: response)

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
        if let delegate = applicationStatus?.clientRegistrationDelegate {
            failedBecauseOfMissingClients = message.parseUploadResponse(response, clientRegistrationDelegate: delegate)
        }
        if !failedBecauseOfMissingClients {
            let shouldUploadFailed = [AssetUploadState.uploadingFullAsset, .uploadingThumbnail].contains(message.uploadState)
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

        if keys.contains(#keyPath(ZMAssetClientMessage.uploadState)) {
            switch message.uploadState {
            case .uploadingPlaceholder: // Asset.Original
                message.resetLocallyModifiedKeys(keys) // We do not want to send a not-uploaded if we failed to upload the Asset.Original
                deleteRequestData(forMessage: message, includingEncryptedAssetData: true)

            case .uploadingFullAsset, .uploadingThumbnail: // Asset.Uploaded && Asset.Preview
                message.didFailToUploadFileData()
                deleteRequestData(forMessage: message, includingEncryptedAssetData: false)

            case .uploadingFailed: return
            case .done: break
            }

            message.uploadState = .uploadingFailed
        }

        // Tracking
        assetAnalytics.trackUploadFailed(for: message, with: request)
    }

    fileprivate func deleteRequestData(forMessage message: ZMAssetClientMessage, includingEncryptedAssetData: Bool) {
        // delete request data
        message.managedObjectContext?.zm_fileAssetCache.deleteRequestData(message)

        // delete asset data
        if includingEncryptedAssetData {
            message.managedObjectContext?.zm_fileAssetCache.deleteAssetData(message, encrypted: true)
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

    fileprivate var v3_isReadyToUploadOriginal: Bool {
        let isNoImage = genericAssetMessage?.assetData?.original.hasImage() == false
        let hasOriginal = genericAssetMessage?.assetData?.hasOriginal() == true
        return transferState == .uploading && uploadState == .uploadingPlaceholder && isNoImage && hasOriginal
    }

    fileprivate var v3_isReadyToUploadThumbnail: Bool {
        let hasAssetId = genericAssetMessage?.assetData?.preview.remote.hasAssetId() == true
        return transferState == .uploading && uploadState == .uploadingThumbnail && hasAssetId
    }

    fileprivate var v3_isReadyToUploadUploaded: Bool {
        let hasAssetId = genericAssetMessage?.assetData?.uploaded.hasAssetId() == true
        return transferState == .uploading && uploadState == .uploadingFullAsset && hasAssetId
    }

    fileprivate var v3_isReadyToUploadNotUploaded: Bool {
        let hasNotUploaded = genericAssetMessage?.assetData?.hasNotUploaded() == true
        let failedOrCancelled = transferState == .failedUpload || transferState == .cancelledUpload
        return failedOrCancelled && hasNotUploaded
    }

    fileprivate static var v3_messageUpdatePredicate: NSPredicate {
        return NSPredicate(format: "delivered == NO && version == 3")
    }
    
}
