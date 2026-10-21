//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
public final class AssetV3UploadRequestStrategy: AbstractRequestStrategy, ZMContextChangeTrackerSource, TearDownCapable {

    let requestFactory = AssetRequestFactory()
    var upstreamSync: ZMUpstreamModifiedObjectSync!
    var preprocessor: AssetsPreprocessor

    private let featureRepository: LegacyFeatureRepository

    public var shouldUseBackgroundSession = true
    let localDomain: String?
    private let isCloudDomain: Bool
    private var uploadGenerations: [NSManagedObjectID: UUID] = [:]
    private var isTornDown = false

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
            update: AssetV3UploadRequestStrategy.updatePredicate(context: managedObjectContext),
            filter: AssetV3UploadRequestStrategy.filterPredicate,
            keysToSync: [#keyPath(ZMAssetClientMessage.transferState)],
            managedObjectContext: managedObjectContext
        )
    }

    public var contextChangeTrackers: [ZMContextChangeTracker] {
        [self, preprocessor, upstreamSync]
    }

    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        upstreamSync.nextRequest(for: apiVersion)
    }

    private static func updatePredicate(context: NSManagedObjectContext) -> NSPredicate {
        let uploads = NSPredicate(
            format: "version >= 3 && delivered == NO && transferState == \(AssetTransferState.uploading.rawValue)"
        )
        return context.canProcessOfflinePendingMessages ? uploads : NSCompoundPredicate(
            andPredicateWithSubpredicates: [uploads, NSPredicate(format: "outboxStateRaw == 0")]
        )
    }

    private static var filterPredicate: NSPredicate {
        NSPredicate(format: "processingState == \(AssetProcessingState.uploading.rawValue)")
    }

    public func tearDown() {
        managedObjectContext.performAndWait {
            isTornDown = true
            uploadGenerations.removeAll()
        }
    }
}

extension AssetV3UploadRequestStrategy: ZMContextChangeTracker {

    // we need to cancel the requests manually as the upstream modified object sync
    // will not pick up a change to keys which are already being synchronized (transferState)
    // WHEN the user cancels a file upload
    public func objectsDidChange(_ object: Set<NSManagedObject>) {
        for message in object.compactMap({ $0 as? ZMAssetClientMessage }) where message.outboxState != .notEnrolled
            && managedObjectContext.canProcessOfflinePendingMessages {
            if message.isDeleted || message.hasBeenDeleted || message.outboxState == .cancelled {
                uploadGenerations.removeValue(forKey: message.objectID)
                cancelOutstandingUploadRequests(forMessage: message)
            } else if message.transferState == .uploadingCancelled {
                uploadGenerations.removeValue(forKey: message.objectID)
                if message.outboxState == .queued { try? message.failQueuedOutboxOperation() }
            } else if message.outboxState == .queued {
                recoverOutboxUpload(message, restoreUploadTracking: false)
            }
        }
        let assetClientMessages = object.compactMap { object -> ZMAssetClientMessage? in
            guard let message = object as? ZMAssetClientMessage,
                  message.version >= 3,
                  message.transferState == .uploadingCancelled,
                  message.outboxState == .notEnrolled || self.managedObjectContext.canProcessOfflinePendingMessages
            else { return nil }
            return message
        }

        assetClientMessages.forEach(cancelOutstandingUploadRequests)
    }

    public func fetchRequestForTrackedObjects() -> NSFetchRequest<NSFetchRequestResult>? {
        guard managedObjectContext.canProcessOfflinePendingMessages else { return nil }
        return ZMAssetClientMessage.sortedFetchRequest(with: NSPredicate(format: "version >= 3 && outboxStateRaw == 1"))
    }

    public func addTrackedObjects(_ objects: Set<NSManagedObject>) {
        guard managedObjectContext.canProcessOfflinePendingMessages else { return }
        for message in objects.compactMap({ $0 as? ZMAssetClientMessage }) where message.outboxState == .queued {
            // Previous-process transport callbacks are not attached to this strategy. Cancel any recorded
            // background task, then reuse retained encrypted bytes and persisted remote references.
            cancelOutstandingUploadRequests(forMessage: message)
            recoverOutboxUpload(message)
        }
    }

    fileprivate func cancelOutstandingUploadRequests(forMessage message: ZMAssetClientMessage) {
        guard let identifier = message.associatedTaskIdentifier else { return }
        applicationStatus?.requestCancellation.cancelTask(with: identifier)
        message.associatedTaskIdentifier = nil
    }

    private func recoverOutboxUpload(_ message: ZMAssetClientMessage, restoreUploadTracking: Bool = true) {
        guard managedObjectContext.canProcessOfflinePendingMessages,
              !message.isDeleted, !message.hasBeenDeleted, !message.isExpired,
              message.transferState == .uploading else { return }
        if restoreUploadTracking { _ = message.recoverOutboxAssetPreparation() }
        guard let content = message.underlyingMessage?.assetData else {
            failOutboxUpload(message)
            return
        }
        let cache = managedObjectContext.zm_fileAssetCache!
        let hasMainBytes = message.isFile ? cache.hasFileData(for: message) : cache.hasImageData(for: message)
        if !content.uploaded.hasAssetID && !hasMainBytes {
            failOutboxUpload(message)
        } else if content.hasPreview && !content.preview.remote.hasAssetID && !cache.hasImageData(for: message) {
            failOutboxUpload(message)
        } else if content.uploaded.hasAssetID && (!content.hasPreview || content.preview.remote.hasAssetID) {
            message.updateTransferState(.uploaded, synchronize: false)
            managedObjectContext.enqueueDelayedSave()
        } else if restoreUploadTracking {
            message.setLocallyModifiedKeys([#keyPath(ZMAssetClientMessage.transferState)])
            managedObjectContext.enqueueDelayedSave()
        }
    }

    private func canUploadOutboxAsset(_ message: ZMAssetClientMessage) -> Bool {
        managedObjectContext.canProcessOfflinePendingMessages && !isTornDown
            && !message.isDeleted && !message.hasBeenDeleted && !message.isExpired
            && message.outboxState == .queued && message.transferState == .uploading
            && message.outboxOperation == .initialMessage
    }

    private func failOutboxUpload(_ message: ZMAssetClientMessage) {
        guard canUploadOutboxAsset(message) else { return }
        uploadGenerations.removeValue(forKey: message.objectID)
        try? message.failQueuedOutboxOperation()
        message.expire(withReason: .other)
        managedObjectContext.enqueueDelayedSave()
    }

}

extension AssetV3UploadRequestStrategy: ZMUpstreamTranscoder {

    public func shouldCreateRequest(
        toSyncObject managedObject: ZMManagedObject,
        forKeys keys: Set<String>,
        withSync sync: Any,
        apiVersion: APIVersion
    ) -> Bool {
        guard let message = managedObject as? ZMAssetClientMessage else { return false }
        guard message.outboxState != .notEnrolled else { return true }
        guard canUploadOutboxAsset(message) else { return false }
        guard message.conversation?.isSelfAnActiveMember == true else {
            failOutboxUpload(message)
            return false
        }
        do {
            try managedObjectContext.save()
        } catch {
            return false
        }
        if message.recoverOutboxAssetPreparation() {
            preprocessor.objectsDidChange([message])
            return false
        }
        guard !message.assets.isEmpty, message.assets.contains(where: { !$0.isUploaded && $0.hasEncrypted }) else {
            failOutboxUpload(message)
            return false
        }
        return true
    }

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
        let enrolled = message.outboxState != .notEnrolled
        guard !enrolled || canUploadOutboxAsset(message) else { return nil }
        let logAttributes: LogAttributes = [
            .public: true,
            .nonce: message.nonce?.safeForLoggingDescription ?? "<nil>"
        ]

        guard let data = asset.encrypted else {
            WireLogger.assets.warn(
                "Encrypted data not available",
                attributes: logAttributes
            )
            if enrolled { failOutboxUpload(message) }
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

        WireLogger.assets.info(
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
            if enrolled { failOutboxUpload(message) }
            return nil
        }

        let generation = UUID()
        if enrolled { uploadGenerations[message.objectID] = generation }

        request.add(ZMTaskCreatedHandler(on: managedObjectContext) { identifier in
            if enrolled {
                guard self.canUploadOutboxAsset(message),
                      self.uploadGenerations[message.objectID] == generation else {
                    self.applicationStatus?.requestCancellation.cancelTask(with: identifier)
                    return
                }
            }
            message.associatedTaskIdentifier = identifier
            if enrolled {
                do {
                    try self.managedObjectContext.save()
                } catch {
                    self.applicationStatus?.requestCancellation.cancelTask(with: identifier)
                    message.associatedTaskIdentifier = nil
                    self.failOutboxUpload(message)
                }
            }
        })

        request.add(ZMTaskProgressHandler(on: managedObjectContext) { progress in
            if enrolled, !self.canUploadOutboxAsset(message)
                || self.uploadGenerations[message.objectID] != generation { return }
            message.progress = progress
            self.managedObjectContext.enqueueDelayedSave()
        })

        return ZMUpstreamRequest(
            keys: [#keyPath(ZMAssetClientMessage.transferState)], transportRequest: request,
            userInfo: enrolled ? [
                "outboxUploadGeneration": generation.uuidString,
                "outboxUploadFingerprint": data.zmSHA256Digest()
            ] : [:]
        )
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
        if message.outboxState != .notEnrolled {
            guard canUploadOutboxAsset(message),
                  keysToParse.contains(#keyPath(ZMAssetClientMessage.transferState)),
                  let generation = requestUserInfo?["outboxUploadGeneration"] as? String,
                  uploadGenerations[message.objectID]?.uuidString == generation,
                  let fingerprint = requestUserInfo?["outboxUploadFingerprint"] as? Data,
                  asset.encrypted?.zmSHA256Digest() == fingerprint else { return false }
        }

        WireLogger.assets.debug(
            "processing response for asset",
            attributes: [.nonce: message.nonce?.safeForLoggingDescription ?? "<nil>"]
        )
        guard
            let payload = response.payload?.asDictionary(),
            let assetId = payload["key"] as? String
        else {
            if message.outboxState != .notEnrolled {
                failOutboxUpload(message)
                return false
            }
            fatal("No asset ID present in payload")
        }

        let token = payload["token"] as? String
        let domain = payload["domain"] as? String

        asset.updateWithAssetId(
            assetId,
            token: token,
            domain: domain
        )
        if message.outboxState != .notEnrolled {
            uploadGenerations.removeValue(forKey: message.objectID)
            message.associatedTaskIdentifier = nil
            guard asset.isUploaded else {
                failOutboxUpload(message)
                return false
            }
        }

        WireLogger.assets.debug(
            "processed response for asset",
            attributes: [.nonce: message.nonce?.safeForLoggingDescription ?? "<nil>"]
        )

        managedObjectContext.zm_fileAssetCache.deleteTransportData(for: message)

        if message.processingState == .done {
            if message.outboxState != .notEnrolled,
               message.underlyingMessage?.assetData?.uploaded.hasAssetID != true {
                failOutboxUpload(message)
                return false
            }
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

    public func shouldRetryFailedRequest(
        for managedObject: ZMManagedObject,
        requestUserInfo: [AnyHashable: Any],
        response: ZMTransportResponse,
        keysToParse: Set<String>
    ) -> Bool {
        guard let message = managedObject as? ZMAssetClientMessage else { return false }
        if message.outboxState == .notEnrolled {
            message.expire(withReason: .other)
            managedObjectContext.zm_fileAssetCache.deleteTransportData(for: message)
            return false
        }
        guard canUploadOutboxAsset(message),
              keysToParse.contains(#keyPath(ZMAssetClientMessage.transferState)),
              let generation = requestUserInfo["outboxUploadGeneration"] as? String,
              uploadGenerations[message.objectID]?.uuidString == generation else { return false }
        uploadGenerations.removeValue(forKey: message.objectID)
        message.associatedTaskIdentifier = nil
        managedObjectContext.zm_fileAssetCache.deleteTransportData(for: message)
        if response.result == .expired || response.result == .cancelled {
            // An upload carries encrypted bytes, not a chat message. Retry the same bytes/references;
            // only the final message handoff uses the uncertain-delivery policy.
            return true
        }
        failOutboxUpload(message)
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
