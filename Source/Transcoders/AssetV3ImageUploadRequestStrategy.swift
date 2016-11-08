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
            guard let asset = message.genericAssetMessage?.assetData else { return false }
            guard asset.original.hasImage() else { return false }
            return asset.original.image.width == 0
        }
    }

    static var v3_imageUploadFilter: NSPredicate {
        return NSPredicate(format: "v3_isReadyToUploadImage == YES")
    }

    /// We want to upload file messages that represent an image where the transfer state is
    /// one of `.uploading`, `.failedUpload`, `.cancelledUpload` and only if we are not done uploading.
    /// We also want to wait for the preprocessing of the file data (encryption) to finish (thus the check for an existing otrKey).
    /// We also need to ensure this file message actually represents an image and that the image preprocessing finished.
    var v3_isReadyToUploadImage : Bool {
        let assetData = genericAssetMessage?.assetData
        return fileMessageData != nil
            && [.uploading, .failedUpload, .cancelledUpload].contains(transferState)
            && uploadState != .done
            && assetData?.hasUploaded() == true && assetData?.uploaded.hasAssetId() == false
            && (assetData?.uploaded.otrKey.count ?? 0) > 0
            && assetData?.original.hasImage() == true
            && (assetData?.original.image.width ?? 0) > 0
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

    fileprivate func update(_ message: ZMAssetClientMessage, withResponse response: ZMTransportResponse, updatedKeys keys: Set<String>) {
        message.markAsSent()
        guard let payload = response.payload?.asDictionary() else { return }
        message.update(withPostPayload: payload, updatedKeys: keys)

        if let status = clientRegistrationStatus {
            _ = message.parseUploadResponse(response, clientDeletionDelegate: status)
        }
    }

    public func updateInsertedObject(_ managedObject: ZMManagedObject, request upstreamRequest: ZMUpstreamRequest, response: ZMTransportResponse) {
        guard let message = managedObject as? ZMAssetClientMessage else { return }
        update(message, withResponse: response, updatedKeys: Set())
    }

    public func updateUpdatedObject(_ managedObject: ZMManagedObject, requestUserInfo: [AnyHashable : Any]? = nil, response: ZMTransportResponse, keysToParse: Set<String>) -> Bool {

        guard let message = managedObject as? ZMAssetClientMessage else { return false }
        guard let payload = response.payload?.asDictionary(), let assetId = payload["key"] as? String else { fatal("No asset ID present in payload: \(response.payload)") }

        if let updated = message.genericAssetMessage?.updated(withAssetId: assetId, token: payload["token"] as? String) {
            message.add(updated)
        }

        update(message, withResponse: response, updatedKeys: keysToParse)

        if case .uploadingFullAsset = message.uploadState,
            keysToParse.contains(ZMAssetClientMessageUploadedStateKey) {
            message.uploadState = .done
            message.managedObjectContext?.zm_imageAssetCache.deleteAssetData(message.nonce, format: .medium, encrypted: true)
            message.resetLocallyModifiedKeys(Set(arrayLiteral: ZMAssetClientMessageUploadedStateKey))
        }

        return false
    }

    public func request(forUpdating managedObject: ZMManagedObject, forKeys keys: Set<String>) -> ZMUpstreamRequest? {
        guard let message = managedObject as? ZMAssetClientMessage else { return nil }
        guard let data = managedObjectContext.zm_imageAssetCache.assetData(message.nonce, format: .medium, encrypted: true) else { return nil }
        guard let request = requestFactory.upstreamRequestForAsset(withData: data, shareable: false, retention: .Persistent) else { return nil }
        return ZMUpstreamRequest(keys: Set(arrayLiteral: ZMAssetClientMessageUploadedStateKey), transportRequest: request)
    }

//    public func shouldCreateRequest(toSyncObject managedObject: ZMManagedObject, forKeys keys: Set<String>, withSync sync: Any) -> Bool {
//        guard let message = managedObject as? ZMAssetClientMessage, let imageAssetStorage = message.imageAssetStorage  else { return false }
//
//        // TODO: V3 image asset storage?
//        if imageAssetStorage.shouldReprocess(for: .medium) {
//            // before we create an upstream request we should check if we can (and should) process image data again
//            // if we can we reschedule processing, this might cause a loop if the message can not be processed whatsoever
//            scheduleImageProcessing(forMessage: message, format: .medium)
//            managedObjectContext.saveOrRollback()
//            return false
//        }
//
//        return true
//    }

    public func shouldRetryToSyncAfterFailed(toUpdate managedObject: ZMManagedObject, request upstreamRequest: ZMUpstreamRequest, response: ZMTransportResponse, keysToParse keys: Set<String>) -> Bool {
        guard let message = managedObject as? ZMAssetClientMessage, let status = clientRegistrationStatus else { return false }

        let shouldRetry = message.parseUploadResponse(response, clientDeletionDelegate: status)
        if !shouldRetry {
            message.uploadState = .uploadingFailed
        }
        return shouldRetry
    }

    public func objectToRefetchForFailedUpdate(of managedObject: ZMManagedObject) -> ZMManagedObject? {
        return nil
    }

    public func shouldProcessUpdatesBeforeInserts() -> Bool {
        return false
    }

//    func scheduleImageProcessing(forMessage message: ZMAssetClientMessage, format : ZMImageFormat) {
//        // TODO: Update to use asset.original.image?
//        let genericMessage = ZMGenericMessage.genericMessage(mediumImageProperties: nil, processedImageProperties: nil, encryptionKeys: nil, nonce: message.nonce.transportString(), format: format, expiresAfter: NSNumber(value: message.deletionTimeout))
//        message.add(genericMessage)
//        RequestAvailableNotification.notifyNewRequestsAvailable(self)
//    }

}
