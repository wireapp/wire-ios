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


extension ZMAssetClientMessage {

    static var v3_imageUploadPredicate: NSPredicate {
        return NSPredicate(
            format: "version == 3 && %K != %d && %K == %d",
            ZMAssetClientMessageUploadedStateKey, ZMAssetUploadState.done.rawValue,
            ZMAssetClientMessageTransferStateKey, ZMFileTransferState.uploading.rawValue
        )
    }

    static var v3_imageProcessingFilter: NSPredicate {
        return NSPredicate { (object, _) in
            guard let message = object as? ZMAssetClientMessage, !message.delivered, message.version == 3 else { return false }
            return message.v3_isReadyToProcessImage
                || message.v3_isReadyToProcessThumbnail
        }
    }

    var v3_isReadyToProcessImage: Bool {
        guard let asset = genericAssetMessage?.assetData else { return false }
        return asset.original.hasImage() && asset.original.image.width == 0

    }

    var v3_isReadyToProcessThumbnail: Bool {
        guard let asset = genericAssetMessage?.assetData, let fileData = fileMessageData else { return false }
        return !asset.original.hasImage()
            && !asset.hasPreview()
            && fileData.previewData != nil
    }

    static var v3_imageUploadFilter: NSPredicate {
        return NSPredicate(format: "v3_isReadyToUploadImageData == YES OR v3_isReadyToUploadThumbnailData == YES")
    }

    /// We want to upload file messages that represent an image where the transfer state is
    /// one of `.uploading`, `.failedUpload`, `.cancelledUpload` and only if we are not done uploading.
    /// We also want to wait for the preprocessing of the file data (encryption) to finish (thus the check for an existing otrKey).
    /// We also need to ensure this file message actually represents an image and that the image preprocessing finished.
    var v3_isReadyToUploadImageData: Bool {
        guard let assetData = genericAssetMessage?.assetData else { return false }
        return fileMessageData != nil
            && [.uploading, .failedUpload, .cancelledUpload].contains(transferState)
            && uploadState != .done
            && assetData.hasUploaded()
            && !assetData.uploaded.hasAssetId()
            && assetData.uploaded.otrKey.count > 0
            && assetData.original.hasImage()
            && assetData.original.image.width > 0
    }

    var v3_isReadyToUploadThumbnailData: Bool {
        guard let assetData = genericAssetMessage?.assetData, !assetData.original.hasImage() else { return false }
        return fileMessageData != nil
            && [.uploading, .failedUpload, .cancelledUpload].contains(transferState)
            && uploadState != .done
            && assetData.hasPreview()
            && !assetData.preview.remote.hasAssetId()
            && assetData.preview.remote.otrKey.count > 0
            && assetData.preview.hasImage()
            && assetData.preview.image.width > 0
    }

}


public final class AssetV3ImageUploadRequestStrategy: ZMObjectSyncStrategy, RequestStrategy, ZMContextChangeTrackerSource {

    fileprivate let preprocessor: ZMImagePreprocessingTracker
    fileprivate let requestFactory = AssetRequestFactory()
    fileprivate weak var clientRegistrationStatus: ClientRegistrationDelegate?
    fileprivate var upstreamSync: ZMUpstreamModifiedObjectSync!

    public init(clientRegistrationStatus: ClientRegistrationDelegate, managedObjectContext: NSManagedObjectContext) {
        self.clientRegistrationStatus = clientRegistrationStatus

        preprocessor = ZMImagePreprocessingTracker(
            managedObjectContext: managedObjectContext,
            imageProcessingQueue: OperationQueue(),
            fetch: NSPredicate(format: "delivered == NO && version == 3"),
            needsProcessingPredicate: ZMAssetClientMessage.v3_imageProcessingFilter,
            entityClass: ZMAssetClientMessage.self
        )

        super.init(managedObjectContext: managedObjectContext)

        upstreamSync = ZMUpstreamModifiedObjectSync(
            transcoder: self,
            entityName: ZMAssetClientMessage.entityName(),
            update: ZMAssetClientMessage.v3_imageUploadPredicate,
            filter: ZMAssetClientMessage.v3_imageUploadFilter,
            keysToSync: [ZMAssetClientMessageUploadedStateKey],
            managedObjectContext: managedObjectContext
        )
    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [preprocessor, upstreamSync]
    }

    public func nextRequest() -> ZMTransportRequest? {
        guard let status = clientRegistrationStatus, status.clientIsReadyForRequests else { return nil }
        return upstreamSync.nextRequest()
    }
}


extension AssetV3ImageUploadRequestStrategy: ZMUpstreamTranscoder {

    public func request(forInserting managedObject: ZMManagedObject, forKeys keys: Set<String>?) -> ZMUpstreamRequest? {
        return nil // no-op
    }

    public func dependentObjectNeedingUpdate(beforeProcessingObject dependant: ZMManagedObject) -> ZMManagedObject? {
        return (dependant as? ZMMessage)?.dependendObjectNeedingUpdateBeforeProcessing()
    }

    public func updateInsertedObject(_ managedObject: ZMManagedObject, request upstreamRequest: ZMUpstreamRequest, response: ZMTransportResponse) {
        // no-op
    }

    public func updateUpdatedObject(_ managedObject: ZMManagedObject, requestUserInfo: [AnyHashable : Any]? = nil, response: ZMTransportResponse, keysToParse: Set<String>) -> Bool {
        guard let message = managedObject as? ZMAssetClientMessage, let genericMessage = message.genericAssetMessage, let asset = genericMessage.assetData else { return false }
        guard let payload = response.payload?.asDictionary(), let assetId = payload["key"] as? String else { fatal("No asset ID present in payload: \(response.payload)") }
        let token: String? = payload["token"] as? String

        if let updated = genericMessage.updatedUploaded(withAssetId: assetId, token: token),
            asset.original.hasImage(),
            message.uploadState == .uploadingFullAsset {

            message.add(updated)
            message.transferState = .uploading
            managedObjectContext.zm_imageAssetCache.deleteAssetData(message.nonce, format: .medium, encrypted: true)
            managedObjectContext.zm_fileAssetCache.deleteRequestData(message.nonce)
            // We need more requests to actually upload the message data (see AssetClientMessageRequestStrategy)
            return true
        } else if let updated = genericMessage.updatedPreview(withAssetId: assetId, token: token),
            message.uploadState == .uploadingThumbnail,
            !asset.original.hasImage(),
            asset.preview.hasImage() {

            message.add(updated)
            message.transferState = .uploading
            managedObjectContext.zm_imageAssetCache.deleteAssetData(message.nonce, format: .medium, encrypted: true)
            managedObjectContext.zm_fileAssetCache.deleteRequestData(message.nonce)
            // We need more requests to actually upload the message data (see AssetClientMessageRequestStrategy)
            return true
        }

        return false
    }

    public func request(forUpdating managedObject: ZMManagedObject, forKeys keys: Set<String>) -> ZMUpstreamRequest? {
        guard let message = managedObject as? ZMAssetClientMessage else { return nil }
        guard let data = managedObjectContext.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: true) else { return nil }
        guard let request = requestFactory.upstreamRequestForAsset(withData: data, shareable: false, retention: .Persistent) else { return nil }
        return ZMUpstreamRequest(keys: Set(arrayLiteral: ZMAssetClientMessageUploadedStateKey), transportRequest: request)
    }

    public func shouldCreateRequest(toSyncObject managedObject: ZMManagedObject, forKeys keys: Set<String>, withSync sync: Any) -> Bool {
        guard let message = managedObject as? ZMAssetClientMessage, let imageAssetStorage = message.imageAssetStorage  else { return false }

        if imageAssetStorage.shouldReprocess(for: .medium) && true == message.fileMessageData?.v3_isImage() {
            // before we create an upstream request we should check if we can (and should) process image data again
            // if we can we reschedule processing, this might cause a loop if the message can not be processed whatsoever
            scheduleImageProcessing(forMessage: message, format: .medium)
            managedObjectContext.saveOrRollback()
            return false
        }

        return true
    }

    public func shouldRetryToSyncAfterFailed(toUpdate managedObject: ZMManagedObject, request upstreamRequest: ZMUpstreamRequest, response: ZMTransportResponse, keysToParse keys: Set<String>) -> Bool {
        guard let message = managedObject as? ZMAssetClientMessage, let status = clientRegistrationStatus else { return false }

        let shouldRetry = message.parseUploadResponse(response, clientDeletionDelegate: status)

        if !shouldRetry {
            if [.expired, .temporaryError, .tryAgainLater].contains(response.result) && message.uploadState == .uploadingThumbnail {
                message.didFailToUploadFileData()
                managedObjectContext.zm_fileAssetCache.deleteRequestData(message.nonce)
            } else {
                // For images we only set the uploadState to failed
                message.uploadState = .uploadingFailed
            }
        }
        return shouldRetry
    }

    public func objectToRefetchForFailedUpdate(of managedObject: ZMManagedObject) -> ZMManagedObject? {
        return nil
    }

    public func shouldProcessUpdatesBeforeInserts() -> Bool {
        return false
    }

    func scheduleImageProcessing(forMessage message: ZMAssetClientMessage, format: ZMImageFormat) {
        // TODO: This is only valid if the message represents an image, not if it is a file and the image we process is a thumbnail
        let genericMessage = ZMGenericMessage.genericMessage(
            withImageSize: .zero,
            mimeType: "",
            size: message.size,
            nonce: message.nonce.transportString(),
            expiresAfter: NSNumber(value: message.deletionTimeout)
        )
        message.add(genericMessage)
        RequestAvailableNotification.notifyNewRequestsAvailable(self)
    }

}
