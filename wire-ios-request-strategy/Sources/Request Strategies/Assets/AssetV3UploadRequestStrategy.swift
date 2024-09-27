//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

// MARK: - AssetV3UploadRequestStrategy

/// AssetV3UploadRequestStrategy is responsible for uploading all the assets associated with a asset message
/// after they've been preprocessed (downscaled & encrypted). After all the assets have been uploaded
/// transfer state is changed to .uploaded which is the signal that the asset message is ready to be sent.
public final class AssetV3UploadRequestStrategy: AbstractRequestStrategy, ZMContextChangeTrackerSource {
    // MARK: Lifecycle

    override public init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus
    ) {
        self.preprocessor = AssetsPreprocessor(managedObjectContext: managedObjectContext)

        super.init(withManagedObjectContext: managedObjectContext, applicationStatus: applicationStatus)
        configuration = .allowsRequestsWhileOnline

        self.upstreamSync = ZMUpstreamModifiedObjectSync(
            transcoder: self,
            entityName: ZMAssetClientMessage.entityName(),
            update: AssetV3UploadRequestStrategy.updatePredicate,
            filter: AssetV3UploadRequestStrategy.filterPredicate,
            keysToSync: [#keyPath(ZMAssetClientMessage.transferState)],
            managedObjectContext: managedObjectContext
        )
    }

    // MARK: Public

    public var shouldUseBackgroundSession = true

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        [preprocessor, upstreamSync, self]
    }

    override public func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        upstreamSync.nextRequest(for: apiVersion)
    }

    // MARK: Internal

    let requestFactory = AssetRequestFactory()
    var upstreamSync: ZMUpstreamModifiedObjectSync!
    var preprocessor: AssetsPreprocessor

    // MARK: Private

    private static var updatePredicate: NSPredicate {
        NSPredicate(
            format: "version >= 3 && delivered == NO && transferState == \(AssetTransferState.uploading.rawValue)"
        )
    }

    private static var filterPredicate: NSPredicate {
        NSPredicate(format: "processingState == \(AssetProcessingState.uploading.rawValue)")
    }
}

// MARK: ZMContextChangeTracker

extension AssetV3UploadRequestStrategy: ZMContextChangeTracker {
    // we need to cancel the requests manually as the upstream modified object sync
    // will not pick up a change to keys which are already being synchronized (transferState)
    // WHEN the user cancels a file upload
    public func objectsDidChange(_ object: Set<NSManagedObject>) {
        let assetClientMessages = object.compactMap { object -> ZMAssetClientMessage? in
            guard let message = object as? ZMAssetClientMessage,
                  message.version >= 3,
                  message.transferState == .uploadingCancelled
            else { return nil }
            return message
        }

        assetClientMessages.forEach(cancelOutstandingUploadRequests)
    }

    public func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        nil
    }

    public func addTrackedObjects(_: Set<NSManagedObject>) {
        // no op
    }

    fileprivate func cancelOutstandingUploadRequests(forMessage message: ZMAssetClientMessage) {
        guard let identifier = message.associatedTaskIdentifier else { return }
        applicationStatus?.requestCancellation.cancelTask(with: identifier)
        message.associatedTaskIdentifier = nil
    }
}

// MARK: ZMUpstreamTranscoder

extension AssetV3UploadRequestStrategy: ZMUpstreamTranscoder {
    public func request(
        forInserting managedObject: ZMManagedObject,
        forKeys keys: Set<String>?,
        apiVersion: APIVersion
    ) -> ZMUpstreamRequest? {
        nil // no-op
    }

    public func dependentObjectNeedingUpdate(beforeProcessingObject dependant: ZMManagedObject) -> Any? {
        (dependant as? ZMMessage)?.dependentObjectNeedingUpdateBeforeProcessing
    }

    public func updateInsertedObject(
        _ managedObject: ZMManagedObject,
        request upstreamRequest: ZMUpstreamRequest,
        response: ZMTransportResponse
    ) {
        // no-op
    }

    public func request(
        forUpdating managedObject: ZMManagedObject,
        forKeys keys: Set<String>,
        apiVersion: APIVersion
    ) -> ZMUpstreamRequest? {
        guard let message = managedObject as? AssetMessage
        else { fatal("Could not cast to ZMAssetClientMessage, it is \(type(of: managedObject)))") }
        guard let asset = message.assets.first(where: { !$0.isUploaded })
        else { return nil } // TODO: jacob are we sure we only have one upload per message active?

        return requestForUploadingAsset(asset, for: managedObject as! ZMAssetClientMessage, apiVersion: apiVersion)
    }

    private func requestForUploadingAsset(
        _ asset: AssetType,
        for message: ZMAssetClientMessage,
        apiVersion: APIVersion
    ) -> ZMUpstreamRequest {
        guard let data = asset.encrypted else { fatal("Encrypted data not available") }
        guard let retention = message.conversation.map(AssetRequestFactory.Retention.init)
        else { fatal("Trying to send message that doesn't have a conversation") }

        WireLogger.assets.debug(
            "sending request for asset",
            attributes: [.nonce: message.nonce?.safeForLoggingDescription ?? "<nil>"]
        )
        var request: ZMTransportRequest? = if shouldUseBackgroundSession {
            requestFactory.backgroundUpstreamRequestForAsset(
                message: message,
                withData: data,
                shareable: false,
                retention: retention,
                apiVersion: apiVersion
            )
        } else {
            requestFactory.upstreamRequestForAsset(
                withData: data,
                shareable: false,
                retention: retention,
                apiVersion: apiVersion
            )
        }

        guard let request else {
            fatal("Could not create asset request")
        }

        request.add(ZMTaskCreatedHandler(on: managedObjectContext) { identifier in
            message.associatedTaskIdentifier = identifier
        })

        request.add(ZMTaskProgressHandler(on: managedObjectContext) { progress in
            message.progress = progress
            self.managedObjectContext.enqueueDelayedSave()
        })

        return ZMUpstreamRequest(keys: [#keyPath(ZMAssetClientMessage.transferState)], transportRequest: request)
    }

    public func updateUpdatedObject(
        _ managedObject: ZMManagedObject,
        requestUserInfo: [AnyHashable: Any]? = nil,
        response: ZMTransportResponse,
        keysToParse: Set<String>
    ) -> Bool {
        guard
            response.result == .success,
            let message = managedObject as? ZMAssetClientMessage,
            let asset = message.assets.first(where: { !$0.isUploaded })
        else {
            WireLogger.assets.warn("response for asset not processed")
            return false
        }

        WireLogger.assets.debug(
            "processing response for asset",
            attributes: [.nonce: message.nonce?.safeForLoggingDescription ?? "<nil>"]
        )
        guard
            let payload = response.payload?.asDictionary(),
            let assetId = payload["key"] as? String
        else {
            fatal("No asset ID present in payload")
        }

        let token = payload["token"] as? String
        let domain = payload["domain"] as? String

        asset.updateWithAssetId(
            assetId,
            token: token,
            domain: domain
        )

        WireLogger.assets.debug(
            "processed response for asset",
            attributes: [.nonce: message.nonce?.safeForLoggingDescription ?? "<nil>"]
        )

        managedObjectContext.zm_fileAssetCache.deleteTransportData(for: message)

        if message.processingState == .done {
            message.updateTransferState(.uploaded, synchronize: false)
            WireLogger.assets.debug(
                "message with asset uploaded",
                attributes: [.nonce: message.nonce?.safeForLoggingDescription ?? "<nil>"]
            )
            return false
        } else {
            // There are more assets to upload
            WireLogger.assets.debug(
                "more assets to upload",
                attributes: [.nonce: message.nonce?.safeForLoggingDescription ?? "<nil>"]
            )

            return true
        }
    }

    public func shouldRetryToSyncAfterFailed(
        toUpdate managedObject: ZMManagedObject,
        request upstreamRequest: ZMUpstreamRequest,
        response: ZMTransportResponse,
        keysToParse keys: Set<String>
    ) -> Bool {
        guard let message = managedObject as? ZMAssetClientMessage else {
            return false
        }

        message.expire()
        managedObjectContext.zm_fileAssetCache.deleteTransportData(for: message)
        return false
    }

    public func requestExpired(
        for managedObject: ZMManagedObject,
        forKeys keys: Set<String>
    ) {
        guard let message = managedObject as? ZMAssetClientMessage else {
            return
        }

        message.expire()
        managedObjectContext.zm_fileAssetCache.deleteTransportData(for: message)
    }

    public func objectToRefetchForFailedUpdate(of managedObject: ZMManagedObject) -> ZMManagedObject? {
        nil
    }

    public func shouldProcessUpdatesBeforeInserts() -> Bool {
        false
    }
}
