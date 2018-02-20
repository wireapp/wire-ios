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

    static var v3_fileUploadPredicate: NSPredicate {
        return NSPredicate(
            format: "version == 3 && %K == %d && %K == %d",
            #keyPath(ZMAssetClientMessage.uploadState), AssetUploadState.uploadingFullAsset.rawValue,
            #keyPath(ZMAssetClientMessage.transferState), ZMFileTransferState.uploading.rawValue
        )
    }

    static var v3_fileUploadFilter: NSPredicate {
        return NSPredicate(format: "v3_isReadyToUploadFile == YES")
    }

    /// We want to upload file messages that represent an image where the transfer state is
    /// one of `.uploading`, `.failedUpload`, `.cancelledUpload` and only if we are uploading the full asset.
    /// We also want to wait for the preprocessing of the file data (encryption) to finish (thus the check for an existing otrKey).
    /// We also need to ensure this file message does not represent an image and that the file preprocessing finished.
    var v3_isReadyToUploadFile: Bool {
        let assetData = genericAssetMessage?.assetData
        return fileMessageData != nil
            && uploadState == .uploadingFullAsset
            && transferState == .uploading
            && assetData?.hasUploaded() == true && assetData?.uploaded.hasAssetId() == false
            && (assetData?.uploaded.otrKey.count ?? 0) > 0
            && assetData?.original.hasImage() == false
    }

    /// We want to preprocess (encrypt) files when they are version 3, have the correct uploadState
    /// and have not yet been preprocessed before (don't have an otrKey in their asset data yet).
    static var v3_needsPreprocessingFilter: NSPredicate {
        return NSPredicate { (obj, _) in
            guard let message = obj as? ZMAssetClientMessage else { return false }
            return message.version == 3
                && message.uploadState == .uploadingFullAsset
                && message.genericAssetMessage?.assetData?.uploaded.hasOtrKey() == false
        }
    }

}


public final class AssetV3FileUploadRequestStrategy: AbstractRequestStrategy, ZMContextChangeTrackerSource {
    
    fileprivate let zmLog = ZMSLog(tag: "Asset V3")

    fileprivate let requestFactory = AssetRequestFactory()
    fileprivate var upstreamSync: ZMUpstreamModifiedObjectSync!
    fileprivate var filePreprocessor : FilePreprocessor
    fileprivate var assetAnalytics: AssetAnalytics

    public override init(withManagedObjectContext managedObjectContext: NSManagedObjectContext, applicationStatus: ApplicationStatus) {
        filePreprocessor = FilePreprocessor(managedObjectContext: managedObjectContext, filter: ZMAssetClientMessage.v3_needsPreprocessingFilter)
        assetAnalytics = AssetAnalytics(managedObjectContext: managedObjectContext)

        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)
        configuration = .allowsRequestsDuringEventProcessing

        upstreamSync = ZMUpstreamModifiedObjectSync(
            transcoder: self,
            entityName: ZMAssetClientMessage.entityName(),
            update: ZMAssetClientMessage.v3_fileUploadPredicate,
            filter: ZMAssetClientMessage.v3_fileUploadFilter,
            keysToSync: [#keyPath(ZMAssetClientMessage.uploadState)],
            managedObjectContext: managedObjectContext
        )
    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        return [filePreprocessor, upstreamSync, self]
    }

    public override func nextRequestIfAllowed() -> ZMTransportRequest? {
        return upstreamSync.nextRequest()
    }
}


extension AssetV3FileUploadRequestStrategy: ZMContextChangeTracker {

    // we need to cancel the requests manually as the upstream modified object sync
    // will not pick up a change to keys which are already being synchronized (uploadState)
    // WHEN the user cancels a file upload
    public func objectsDidChange(_ object: Set<NSManagedObject>) {
        let assetClientMessages = object.flatMap { object -> ZMAssetClientMessage? in
            guard let message = object as? ZMAssetClientMessage,
                message.version == 3,
                nil != message.fileMessageData && message.transferState == .cancelledUpload
                else { return nil }
            return message
        }

        assetClientMessages.forEach(cancelOutstandingUploadRequests)
    }

    public func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        return nil
    }

    public func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        // no op
    }

    fileprivate func cancelOutstandingUploadRequests(forMessage message: ZMAssetClientMessage) {
        guard let identifier = message.associatedTaskIdentifier else { return }
        applicationStatus?.requestCancellation.cancelTask(with: identifier)
    }

}


extension AssetV3FileUploadRequestStrategy: ZMUpstreamTranscoder {

    public func request(forInserting managedObject: ZMManagedObject, forKeys keys: Set<String>?) -> ZMUpstreamRequest? {
        return nil // no-op
    }

    public func dependentObjectNeedingUpdate(beforeProcessingObject dependant: ZMManagedObject) -> Any? {
        return (dependant as? ZMMessage)?.dependentObjectNeedingUpdateBeforeProcessing
    }

    fileprivate func update(_ message: ZMAssetClientMessage, withResponse response: ZMTransportResponse, updatedKeys keys: Set<String>) {
        guard let payload = response.payload?.asDictionary() else { return }
        message.update(withPostPayload: payload, updatedKeys: keys)
        if let delegate = applicationStatus?.clientRegistrationDelegate {
            _ = message.parseUploadResponse(response, clientRegistrationDelegate: delegate)
        }
    }

    public func updateInsertedObject(_ managedObject: ZMManagedObject, request upstreamRequest: ZMUpstreamRequest, response: ZMTransportResponse) {
     // no-op
    }
    
    public func shouldCreateRequest(toSyncObject managedObject: ZMManagedObject, forKeys keys: Set<String>, withSync sync: Any) -> Bool {
        guard let message = managedObject as? ZMAssetClientMessage else {
            zmLog.warn("Could not cast to ZMAssetClientMessage, it is \(type(of: managedObject)))")
            return false
        }
        
        guard let name = message.fileMessageData?.filename else {
            zmLog.warn("Message file data does not contain filename")
            return false
        }

        guard managedObjectContext.zm_fileAssetCache.hasDataOnDisk(message.nonce, fileName: name, encrypted: true) else {
            // if the asset data is missing, we should delete the message
            managedObjectContext.delete(message)
            managedObjectContext.enqueueDelayedSave()
            zmLog.warn("Asset data is missing from file cache. Message nonce: \(message.nonce)")
            return false
        }
        
        return true
    }

    public func request(forUpdating managedObject: ZMManagedObject, forKeys keys: Set<String>) -> ZMUpstreamRequest? {
        guard let message = managedObject as? ZMAssetClientMessage else { fatal("Could not cast to ZMAssetClientMessage, it is \(type(of: managedObject)))") }

        if message.uploadState == .uploadingFullAsset {
            return requestToUploadFullAsset(for: message)
        } else {
            fatal("Wrong message upload state: \(message.uploadState.rawValue))")
        }

        return nil
    }
    
    private func requestToUploadFullAsset(for message: ZMAssetClientMessage) -> ZMUpstreamRequest? {
        guard let name = message.fileMessageData?.filename else { fatal("Message file data does not contain filename") }
        guard let data = managedObjectContext.zm_fileAssetCache.assetData(message.nonce, fileName: name, encrypted: true) else { fatal("Could not find file in cache") }
        guard let request = requestFactory.backgroundUpstreamRequestForAsset(message: message, withData: data, shareable: false, retention: .persistent) else { fatal("Could not create asset request") }

        request.add(ZMTaskCreatedHandler(on: managedObjectContext) { identifier in
            message.associatedTaskIdentifier = identifier
        })
        request.add(ZMCompletionHandler(on: managedObjectContext) { [weak request] response in
            message.associatedTaskIdentifier = nil
            if response.result == .expired || response.result == .temporaryError || response.result == .tryAgainLater {
                self.failMessageUpload(message, keys: [#keyPath(ZMAssetClientMessage.uploadState)], request: request)
            }
        })
        request.add(ZMTaskProgressHandler(on: self.managedObjectContext) { progress in
            message.progress = progress
            self.managedObjectContext.enqueueDelayedSave()
        })
        return ZMUpstreamRequest(keys: [#keyPath(ZMAssetClientMessage.uploadState)], transportRequest: request)
    }

    public func updateUpdatedObject(_ managedObject: ZMManagedObject, requestUserInfo: [AnyHashable : Any]? = nil, response: ZMTransportResponse, keysToParse: Set<String>) -> Bool {

        guard keysToParse.contains(#keyPath(ZMAssetClientMessage.uploadState)), response.result == .success else { return false }
        guard let message = managedObject as? ZMAssetClientMessage else { return false }
        guard let payload = response.payload?.asDictionary(), let assetId = payload["key"] as? String else {
            fatal("No asset ID present in payload: \(String(describing: response.payload))")
        }

        if let delegate = applicationStatus?.clientRegistrationDelegate {
            // this will remove deleted clients that are returned in the payload
            _ = message.parseUploadResponse(response, clientRegistrationDelegate: delegate)
        }
        
        if let updated = message.genericAssetMessage?.updatedUploaded(withAssetId: assetId, token: payload["token"] as? String) {
            message.add(updated)
        }

        update(message, withResponse: response, updatedKeys: keysToParse)

        if message.uploadState == .uploadingFullAsset, keysToParse.contains(#keyPath(ZMAssetClientMessage.uploadState)) {
            deleteRequestData(forMessage: message, includingEncryptedAssetData: true)

            // We need more requests to actually upload the message data
            return true
        }
        
        return false
    }

    /// marks the upload as failed
    fileprivate func failMessageUpload(_ message: ZMAssetClientMessage, keys: Set<String>, request: ZMTransportRequest?) {

        if message.transferState != .cancelledUpload {
            message.transferState = .failedUpload
            message.expire()
        }

        if keys.contains(#keyPath(ZMAssetClientMessage.uploadState)) {
            if message.uploadState == .uploadingFullAsset {
                message.didFailToUploadFileData()
                deleteRequestData(forMessage: message, includingEncryptedAssetData: false)
            }

            message.uploadState = .uploadingFailed
        }

        // Tracking
        assetAnalytics.trackUploadFailed(for: message, with: request)
    }

    public func shouldRetryToSyncAfterFailed(toUpdate managedObject: ZMManagedObject,
                                             request upstreamRequest: ZMUpstreamRequest,
                                             response: ZMTransportResponse,
                                             keysToParse keys: Set<String>)-> Bool {
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

    public func objectToRefetchForFailedUpdate(of managedObject: ZMManagedObject) -> ZMManagedObject? {
        return nil
    }

    public func shouldProcessUpdatesBeforeInserts() -> Bool {
        return false
    }

    fileprivate func deleteRequestData(forMessage message: ZMAssetClientMessage, includingEncryptedAssetData: Bool) {
        // delete request data
        message.managedObjectContext?.zm_fileAssetCache.deleteRequestData(message.nonce)

        // delete asset data
        if includingEncryptedAssetData, let cacheKey = message.genericAssetMessage?.v3_fileCacheKey {
            message.managedObjectContext?.zm_fileAssetCache.deleteAssetData(message.nonce, fileName: cacheKey, encrypted: true)
        }
    }
    
}
