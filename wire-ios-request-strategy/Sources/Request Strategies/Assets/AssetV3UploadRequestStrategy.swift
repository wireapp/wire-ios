//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireDataModel
import WireLogging

/// AssetV3UploadRequestStrategy is responsible for uploading all the assets associated with a asset message
/// after they've been preprocessed (downscaled & encrypted). After all the assets have been uploaded
/// transfer state is changed to .uploaded which is the signal that the asset message is ready to be sent.
public final class AssetV3UploadRequestStrategy: AbstractRequestStrategy, ZMContextChangeTrackerSource {

    let requestFactory = AssetRequestFactory()
    var upstreamSync: ZMUpstreamModifiedObjectSync!
    var preprocessor: AssetsPreprocessor

    private let featureRepository: LegacyFeatureRepository

    public var shouldUseBackgroundSession = true
    let localDomain: String?
    private let isCloudDomain: Bool

    private var shouldUploadExtraMetaData: Bool {
        guard !isCloudDomain else { return false }
        return managedObjectContext.performAndWait {
            featureRepository.fetchAssetAuditLog().status == .enabled
        }
    }

    public init(
        withManagedObjectContext managedObjectContext: NSManagedObjectContext,
        applicationStatus: ApplicationStatus,
        localDomain: String?,
        isCloudDomain: Bool
    ) {
        self.preprocessor = AssetsPreprocessor(managedObjectContext: managedObjectContext)
        self.localDomain = localDomain
        self.isCloudDomain = isCloudDomain
        self.featureRepository = LegacyFeatureRepository(context: managedObjectContext)

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

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        [preprocessor, upstreamSync, self]
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        upstreamSync.nextRequest(for: apiVersion)
    }

    private static var updatePredicate: NSPredicate {
        NSPredicate(
            format: "version >= 3 && delivered == NO && transferState == \(AssetTransferState.uploading.rawValue)"
        )
    }

    private static var filterPredicate: NSPredicate {
        NSPredicate(format: "processingState == \(AssetProcessingState.uploading.rawValue)")
    }
}

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

    public func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        // no op
    }

    fileprivate func cancelOutstandingUploadRequests(forMessage message: ZMAssetClientMessage) {
        guard let identifier = message.associatedTaskIdentifier else { return }
        applicationStatus?.requestCancellation.cancelTask(with: identifier)
        message.associatedTaskIdentifier = nil
    }

}

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
        guard let message = managedObject as? ZMAssetClientMessage else {
            WireLogger.assets.error("Could not cast to ZMAssetClientMessage, it is \(type(of: managedObject)))")
            return nil
        }
        guard let asset = message.assets.first(where: { !$0.isUploaded }) else { return nil }

        return requestForUploadingAsset(asset, for: message, apiVersion: apiVersion)
    }

    private func requestForUploadingAsset(
        _ asset: AssetType,
        for message: ZMAssetClientMessage,
        apiVersion: APIVersion
    ) -> ZMUpstreamRequest? {
        let logAttributes: LogAttributes = [
            .public: true,
            .nonce: message.nonce?.safeForLoggingDescription ?? "<nil>"
        ]

        guard let data = asset.encrypted else {
            WireLogger.assets.warn(
                "Encrypted data not available",
                attributes: logAttributes
            )
            return nil
        }

        guard let conversation = message.conversation else {
            WireLogger.assets.warn(
                "Trying to send message that doesn't have a conversation",
                attributes: logAttributes
            )
            return nil
        }

        let retention = AssetRequestFactory.Retention(conversation: conversation)

        var extraMetaData: AssetRequestFactory.AssetAuditLogMetaData?
        if shouldUploadExtraMetaData {
            guard
                let asset = message.underlyingMessage?.assetData?.original,
                let domain = conversation.domain ?? localDomain
            else {
                WireLogger.assets.warn(
                    "should include extra metadata but not able to",
                    attributes: logAttributes
                )
                return nil
            }

            let conversationID = QualifiedID(
                uuid: conversation.remoteIdentifier,
                domain: domain
            )

            extraMetaData = .init(
                conversationID: conversationID,
                fileName: asset.name,
                mimeType: asset.mimeType
            )
        }

        WireLogger.assets.debug(
            "sending request for asset",
            attributes: logAttributes
        )
        let request: ZMTransportRequest? = if shouldUseBackgroundSession {
            requestFactory.backgroundUpstreamRequestForAsset(
                message: message,
                withData: data,
                shareable: false,
                retention: retention,
                assetAuditLogMetaData: extraMetaData,
                apiVersion: apiVersion
            )
        } else {
            requestFactory.upstreamRequestForAsset(
                withData: data,
                shareable: false,
                retention: retention,
                assetAuditLogMetaData: extraMetaData,
                apiVersion: apiVersion
            )
        }

        guard let request else {
            return nil
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

        message.expire(withReason: .other)
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

        message.expire(withReason: .other)
        managedObjectContext.zm_fileAssetCache.deleteTransportData(for: message)
    }

    public func objectToRefetchForFailedUpdate(of managedObject: ZMManagedObject) -> ZMManagedObject? {
        nil
    }

    public func shouldProcessUpdatesBeforeInserts() -> Bool {
        false
    }

}
